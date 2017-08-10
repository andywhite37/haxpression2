package haxpression2.eval;

using thx.Arrays;
import thx.Functions.identity;
using thx.Options;
using thx.Maps;
import thx.Nel;
import thx.Unit;
import thx.Validation.*;

import haxpression2.Expr;
using haxpression2.AnnotatedExpr;
import haxpression2.eval.ExprEvaluatorOptions;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.render.ExprRenderer;

class AnnotatedExprEvaluator {
  public static function canEval<TError, V, A>(ae : AnnotatedExpr<V, A>, options: ExprEvaluatorOptions<AnnotatedExpr<V, A>, TError, V>) : Bool {
    return switch ae.expr {
      case ELit(_) : true;
      case EVar(name) : options.variables.getOption(name).toBool();
      case EBinOp(op, _, left, right) : options.binOps.getOption(op).toBool() && canEval(left, options) && canEval(right, options);
      case EUnOpPre(op, _, operand) : options.unOps.pre.getOption(op).toBool() && canEval(operand, options);
      case EFunc(name, args) : options.functions.getOption(name).toBool() && args.all(arg -> canEval(arg, options));
    };
  }

  public static function eval<TError, V, A>(ae : AnnotatedExpr<V, A>, options: ExprEvaluatorOptions<AnnotatedExpr<V, A>, TError, V>) : ExprEvaluatorResult<AnnotatedExpr<V, A>, TError, V> {
    return switch ae.expr {
      case ELit(value) : successNel(value);

      case EVar(name) :
        options.variables.getOption(name).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no variable definition was given for name: $name', ae) }),
          value -> successNel(value)
        );

      case EFunc(name, argExprs) :
        options.functions.getOption(name).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no function definition was given for function name: $name', ae) }),
          func ->
            argExprs.traverseValidation(argExpr -> eval(argExpr, options), Nel.semigroup())
              .flatMapV(argValues -> func.eval(argValues).leftMap(errors -> errors.map(error -> { expr: ae, error: options.onError(error, ae) })))
        );

      case EUnOpPre(operator, precedence, operandExpr) :
        options.unOps.pre.getOption(operator).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no prefix unary operator definition was given for operator: $operator', ae) }),
          preOp -> eval(operandExpr, options)
            .flatMapV(operandValue -> preOp.eval(operandValue).leftMap(errors -> errors.map(error -> { expr: ae, error: options.onError(error, ae) })))
        );

      case EBinOp(operator, precedence, leftExpr, rightExpr) :
        options.binOps.getOption(operator).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no binary operator definition was given for operator: $operator', ae) }),
          binOp -> val2(
            (leftValue, rightValue) -> binOp.eval(leftValue, rightValue).leftMap(errors -> errors.map(error -> { expr: ae, error: options.onError(error, ae) })),
            eval(leftExpr, options),
            eval(rightExpr, options),
            Nel.semigroup()
          )
          .flatMapV(identity)
        );
    };
  }

  public static function evalString<V, N, A>(
    input: String,
    parserOptions: ExprParserOptions<V, N, A>,
    evaluatorOptions: ExprEvaluatorOptions<AnnotatedExpr<V, A>, EvalError<AnnotatedExpr<V, A>>, V>
  ) : ExprStringEvaluatorResult<AnnotatedExpr<V, A>, ParseError<AnnotatedExpr<V, A>>, EvalError<AnnotatedExpr<V, A>>, V> {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(parseError) : ParseError(parseError);
      case Right(ae) : switch eval(ae, evaluatorOptions) {
        case Left(errors) : EvalErrors(errors);
        case Right(value) : Evaluated(value);
      };
    };
  }

  public static function canSimplify<TError, V, A>(ae : AnnotatedExpr<V, A>, options: ExprEvaluatorOptions<AnnotatedExpr<V, A>, TError, V>) : Bool {
    return switch ae.expr {
      case ELit(_) : false;

      case EVar(name) : options.variables.getOption(name).toBool();

      case EBinOp(op, _, left, right) :
        canSimplify(left, options) ||
        canSimplify(right, options) ||
        (options.binOps.getOption(op).toBool() && left.isAnyLit() && right.isAnyLit());

      case EUnOpPre(op, _, operand) :
        canSimplify(operand, options) ||
        (options.unOps.pre.getOption(op).toBool() && operand.isAnyLit());

      case EFunc(name, args) :
        args.any(arg -> canSimplify(arg, options)) ||
        (options.functions.getOption(name).toBool() && args.all(arg -> arg.isAnyLit()));
    };
  }

  public static function simplify<TError, V, A>(ae : AnnotatedExpr<V, A>, options: ExprEvaluatorOptions<AnnotatedExpr<V, Unit>, TError, V>) : AnnotatedExpr<V, Unit> {
    var simplified = AnnotatedExpr.voidAnnotation(ae);
    while (canSimplify(simplified, options)) {
      simplified = simplifyOnce(simplified, options);
    }
    return simplified;
  }

  public static function simplifyOnce<TError, V>(ae : AnnotatedExpr<V, Unit>, options: ExprEvaluatorOptions<AnnotatedExpr<V, Unit>, TError, V>) : AnnotatedExpr<V, Unit> {
    function tryEval(ae : AnnotatedExpr<V, Unit>) : AnnotatedExpr<V, Unit> {
      return switch eval(ae, options) {
        case Left(errors) :
          // Note: this is ignoring evaluation errors for simplify, because it's possible to simplify an expression with
          // some (incomplete) evaluation options, and then further simplify/evaluate it later with additional options.
          trace('Warning: ignoring evaluation error while trying to simplify: $ae\n$errors');
          ae;
        case Right(value) :
          new AnnotatedExpr(ELit(value), unit);
      };
    }

    return switch ae.expr {
      case ELit(_) : ae.voidAnnotation();

      case EVar(name) :
        options.variables.getOption(name).cataf(
          () -> ae.voidAnnotation(),
          value -> new AnnotatedExpr(ELit(value), unit)
        );

      case EBinOp(op, prec, left, right) :
        var simpleLeft = tryEval(left.voidAnnotation());
        var simpleRight = tryEval(right.voidAnnotation());
        var simpleBinOp = new AnnotatedExpr(EBinOp(op, prec, simpleLeft, simpleRight), unit);
        tryEval(simpleBinOp);

      case EUnOpPre(op, prec, operand) :
        var simpleOperand = tryEval(operand.voidAnnotation());
        var simpleUnOp = new AnnotatedExpr(EUnOpPre(op, prec, simpleOperand), unit);
        tryEval(simpleUnOp);

      case EFunc(name, args) :
        var simpleArgs = args.map(tryEval);
        var simpleFunc = new AnnotatedExpr(EFunc(name, simpleArgs), unit);
        tryEval(simpleFunc);
    };
  }

  public static function simplifyString<TError, V, N, A>(
    input : String,
    parserOptions: ExprParserOptions<V, N, A>,
    evalOptions: ExprEvaluatorOptions<AnnotatedExpr<V, Unit>, TError, V>,
    valueToString: V -> String
  ) : String {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(_) :
        // Failed to parse input - just return it as-is
        // TODO: not sure if this should fail here
        input;
      case Right(ae) :
        ExprRenderer.renderString(simplify(ae, evalOptions).expr, valueToString);
    };
  }
}
