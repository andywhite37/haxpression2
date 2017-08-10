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
import haxpression2.AnnotatedExpr.create as ae;
import haxpression2.eval.ExprEvaluatorOptions;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.render.ExprRenderer;

class AnnotatedExprEvaluator {
  public static function substitute<V, A>(target : AnnotatedExpr<V, A>, name : String, sub : AnnotatedExpr<V, A>) : AnnotatedExpr<V, Unit> {
    return switch target.expr {
      case ELit(_) : target.voidAnnotation();
      case EVar(n) if (n == name) : sub.voidAnnotation();
      case EVar(_) : target.voidAnnotation();
      case EFunc(name, args) : ae(EFunc(name, args.map(arg -> substitute(arg, name, sub))), unit);
      case EBinOp(operator, precedence, left, right) : ae(EBinOp(operator, precedence, substitute(left, name, sub), substitute(right, name, sub)), unit);
      case EUnOpPre(operator, precedence, operand) : ae(EUnOpPre(operator, precedence, substitute(operand, name, sub)), unit);
    };
  }

  public static function substituteMap<V, A>(target : AnnotatedExpr<V, A>, subs : Map<String, AnnotatedExpr<V, A>>) : AnnotatedExpr<V, Unit> {
    return subs.foldLeftWithKeys(function(target : AnnotatedExpr<V, Unit>, name : String, sub : AnnotatedExpr<V, A>) : AnnotatedExpr<V, Unit> {
      return substitute(target, name, sub.voidAnnotation());
    }, target.voidAnnotation());
  }

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

}
