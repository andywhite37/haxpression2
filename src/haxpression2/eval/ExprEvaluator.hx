package haxpression2.eval;

using thx.Arrays;
import thx.Functions.identity;
using thx.Options;
using thx.Maps;
import thx.Nel;
import thx.Unit;
import thx.Validation.*;

using haxpression2.AnnotatedExpr;
using haxpression2.Expr;
import haxpression2.eval.ExprEvaluatorOptions;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.render.ExprRenderer;

class ExprEvaluator {
  public static function eval<TError, V, A>(expr : Expr<V, A>, options: ExprEvaluatorOptions<Expr<V, A>, TError, V>) : ExprEvaluatorResult<Expr<V, A>, TError, V> {
    return switch expr {
      case ELit(value) : successNel(value);

      case EVar(name) :
        options.variables.getOption(name).cataf(
          () -> failureNel({ expr: expr, error: options.onError('no definition was given for variable: $name', expr) }),
          value -> successNel(value)
        );

      case EFunc(name, argExprs) :
        options.functions.getOption(name).cataf(
          () -> failureNel({ expr: expr, error: options.onError('no definition was given for function: $name', expr) }),
          func ->
            argExprs.traverseValidation(argExpr -> eval(argExpr.expr, options), Nel.semigroup())
              .flatMapV(argValues -> func.eval(argValues).leftMap(errors -> errors.map(error -> { expr: expr, error: options.onError(error, expr) })))
        );

      case EUnOpPre(operator, precendece, operandExpr) :
        options.unOps.pre.getOption(operator).cataf(
          () -> failureNel({ expr: expr, error: options.onError('no definition given for unary prefix operator: $operator', expr) }),
          unOp -> eval(operandExpr.expr, options)
            .flatMapV(operandValue -> unOp.eval(operandValue).leftMap(errors -> errors.map(error -> { expr: expr, error: options.onError(error, expr) })))
        );

      case EBinOp(operator, precedence, leftExpr, rightExpr) :
        options.binOps.getOption(operator).cataf(
          () -> failureNel({ expr: expr, error: options.onError('no definition was given for binary operator: $operator', expr) }),
          binOp -> val2(
            (leftValue, rightValue) -> binOp.eval(leftValue, rightValue).leftMap(errors -> errors.map(error -> { expr: expr, error: options.onError(error, expr) })),
            eval(leftExpr.expr, options),
            eval(rightExpr.expr, options),
            Nel.semigroup()
          ).flatMapV(identity)
        );
    };
  }

  public static function evalString<V, N, A>(
    input: String,
    parserOptions: ExprParserOptions<V, N, A>,
    evalOptions: ExprEvaluatorOptions<Expr<V, A>, EvalError<Expr<V, A>>, V>
  ) : ExprStringEvaluatorResult<Expr<V, A>, ParseError<AnnotatedExpr<V, A>>, EvalError<Expr<V, A>>, V> {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(parseError) : ParseError(parseError);
      case Right(ae) : switch eval(ae.expr, evalOptions) {
        case Left(errors) : EvalErrors(errors);
        case Right(value) : Evaluated(value);
      };
    };
  }

  public static function canSimplify<TError, V, A>(expr : Expr<V, A>, options: ExprEvaluatorOptions<Expr<V, A>, TError, V>) : Bool {
    return switch expr {
      case ELit(_) : false;

      case EVar(name) : options.variables.getOption(name).toBool();

      case EBinOp(op, _, left, right) :
        canSimplify(left.expr, options) ||
        canSimplify(right.expr, options) ||
        (options.binOps.getOption(op).toBool() && left.expr.isAnyLit() && right.expr.isAnyLit());

      case EUnOpPre(op, _, operand) :
        canSimplify(operand.expr, options) ||
        (options.unOps.pre.getOption(op).toBool() && operand.isAnyLit());

      case EFunc(name, args) :
        args.any(arg -> canSimplify(arg.expr, options)) ||
        (options.functions.getOption(name).toBool() && args.all(arg -> arg.isAnyLit()));
    };
  }

  public static function simplify<TError, V>(expr : Expr<V, Unit>, options: ExprEvaluatorOptions<Expr<V, Unit>, TError, V>) : Expr<V, Unit> {
    var simplified = expr;
    while (canSimplify(simplified, options)) {
      simplified = simplifyOnce(simplified, options);
    }
    return simplified;
  }

  public static function simplifyOnce<TError, V>(expr : Expr<V, Unit>, options: ExprEvaluatorOptions<Expr<V, Unit>, TError, V>) : Expr<V, Unit> {
    function tryEval(ae : AnnotatedExpr<V, Unit>) : AnnotatedExpr<V, Unit> {
      return switch ExprEvaluator.eval(ae.expr, options) {
        case Left(errors) :
          // Note: this is ignoring evaluation errors for simplify, because it's possible to simplify an expression with
          // some (incomplete) evaluation options, and then further simplify/evaluate it later with additional options.
          trace('Warning: ignoring evaluation error while trying to simplify: $ae\n$errors');
          ae;
        case Right(value) :
          new AnnotatedExpr(ELit(value), unit);
      };
    }

    return switch expr {
      case ELit(_) : expr;

      case EVar(name) :
        options.variables.getOption(name).cataf(
          () -> expr,
          value -> ELit(value)
        );

      case EBinOp(op, prec, left, right) :
        var simpleLeft = tryEval(left);
        var simpleRight = tryEval(right);
        var simpleBinOp = new AnnotatedExpr(EBinOp(op, prec, simpleLeft, simpleRight), unit);
        tryEval(simpleBinOp).expr;

      case EUnOpPre(op, prec, operand) :
        var simpleOperand = tryEval(operand.voidAnnotation());
        var simpleUnOp = new AnnotatedExpr(EUnOpPre(op, prec, simpleOperand), unit);
        tryEval(simpleUnOp).expr;

      case EFunc(name, args) :
        var simpleArgs = args.map(tryEval);
        var simpleFunc = new AnnotatedExpr(EFunc(name, simpleArgs), unit);
        tryEval(simpleFunc).expr;
    };
  }

  public static function simplifyString<TError, V, N>(
    input : String,
    parserOptions: ExprParserOptions<V, N, Unit>,
    evalOptions: ExprEvaluatorOptions<Expr<V, Unit>, TError, V>,
    valueToString: V -> String
  ) : String {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(error) :
        // Failed to parse input - just return it as-is
        trace('Warning: ignoring parse error while trying to simplify: $input\n$error');
        input;
      case Right(ae) :
        ExprRenderer.renderString(simplify(ae.expr, evalOptions), valueToString);
    };
  }
}
