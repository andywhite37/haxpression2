package haxpression2.eval;

using thx.Arrays;
import thx.Functions.identity;
using thx.Options;
using thx.Maps;
import thx.Nel;
import thx.Validation.*;

import haxpression2.Expr;
import haxpression2.eval.ExprEvaluatorOptions;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;

class ExprEvaluator {
  public static function eval<TError, V, A>(expr : Expr<V, A>, options: ExprEvaluatorOptions<Expr<V, A>, TError, V, A>) : ExprEvaluatorResult<Expr<V, A>, TError, V> {
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
              .flatMapV(argValues -> func(argValues).leftMap(errors -> errors.map(error -> { expr: expr, error: options.onError(error, expr) })))
        );

      case EUnOpPre(operator, precendece, operandExpr) :
        options.unOps.pre.getOption(operator).cataf(
          () -> failureNel({ expr: expr, error: options.onError('no definition given for unary prefix operator: $operator', expr) }),
          unOp -> eval(operandExpr.expr, options)
            .flatMapV(operandValue -> unOp(operandValue).leftMap(errors -> errors.map(error -> { expr: expr, error: options.onError(error, expr) })))
        );

      case EBinOp(operator, precedence, leftExpr, rightExpr) :
        options.binOps.getOption(operator).cataf(
          () -> failureNel({ expr: expr, error: options.onError('no definition was given for binary operator: $operator', expr) }),
          binOp -> val2(
            (leftValue, rightValue) -> binOp(leftValue, rightValue).leftMap(errors -> errors.map(error -> { expr: expr, error: options.onError(error, expr) })),
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
    evalOptions: ExprEvaluatorOptions<Expr<V, A>, EvalError<Expr<V, A>>, V, A>
  ) : ExprStringEvaluatorResult<Expr<V, A>, ParseError<AnnotatedExpr<V, A>>, EvalError<Expr<V, A>>, V> {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(parseError) : ParseError(parseError);
      case Right(ae) : switch eval(ae.expr, evalOptions) {
        case Left(errors) : EvalErrors(errors);
        case Right(value) : Evaluated(value);
      };
    };
  }
}
