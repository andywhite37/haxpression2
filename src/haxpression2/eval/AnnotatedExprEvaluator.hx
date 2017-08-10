package haxpression2.eval;

using thx.Arrays;
import thx.Functions.identity;
using thx.Options;
using thx.Maps;
import thx.Nel;
import thx.Validation.*;

import haxpression2.eval.ExprEvaluatorOptions;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;

class AnnotatedExprEvaluator {
  public static function eval<TError, V, A>(ae : AnnotatedExpr<V, A>, options: ExprEvaluatorOptions<AnnotatedExpr<V, A>, TError, V, A>) : ExprEvaluatorResult<AnnotatedExpr<V, A>, TError, V> {
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
              .flatMapV(argValues -> func(argValues).leftMap(errors -> errors.map(error -> { expr: ae, error: options.onError(error, ae) })))
        );

      case EUnOpPre(operator, precedence, operandExpr) :
        options.unOps.pre.getOption(operator).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no prefix unary operator definition was given for operator: $operator', ae) }),
          preOp -> eval(operandExpr, options)
            .flatMapV(operandValue -> preOp(operandValue).leftMap(errors -> errors.map(error -> { expr: ae, error: options.onError(error, ae) })))
        );

      case EBinOp(operator, precedence, leftExpr, rightExpr) :
        options.binOps.getOption(operator).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no binary operator definition was given for operator: $operator', ae) }),
          binOp -> val2(
            (leftValue, rightValue) -> binOp(leftValue, rightValue).leftMap(errors -> errors.map(error -> { expr: ae, error: options.onError(error, ae) })),
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
    evaluatorOptions: ExprEvaluatorOptions<AnnotatedExpr<V, A>, EvalError<AnnotatedExpr<V, A>>, V, A>
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
