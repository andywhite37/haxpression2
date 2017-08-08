package haxpression2.eval;

using thx.Arrays;
import thx.Functions.identity;
using thx.Options;
using thx.Maps;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;

import haxpression2.Expr;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;

/**
 * Function for evaluating a unary operator expression (VNel allows for failures)
 */
typedef EvalUnOp<V> = V -> VNel<String, V>;

/**
 * Function for evaluating a binary operator expression (VNel allows for failures)
 */
typedef EvalBinOp<V> = V -> V -> VNel<String, V>;

/**
 * Function for evaluating a function expression (VNel allows for failures)
 */
typedef EvalFunc<V> = Array<V> -> VNel<String, V>;

/**
 * Structure for caller to supply values for variables, and definitions for functions and operators
 * for use in an evaluation.
 */
typedef EvalOptions<Expr, Error, V, A> = {
  onError: String -> Expr -> Error,
  variables: Map<String, V>,
  unOps: {
    pre: Map<String, EvalUnOp<V>>,
    post: Map<String, EvalUnOp<V>>
  },
  binOps: Map<String, EvalBinOp<V>>,
  functions: Map<String, EvalFunc<V>>
};

typedef EvalResult<Expr, Error, V> = VNel<{ expr: Expr, error: Error }, V>;

enum ParseEvalResult<Expr, ParseError, EvalError, V> {
  ParseError(error : ParseError);
  EvalErrors(errors : Nel<{ expr: Expr, error: EvalError }>);
  Success(value : V);
}

class ExprEvaluator {
  public static function eval<Error, V, A>(expr : Expr<V, A>, options: EvalOptions<Expr<V, A>, Error, V, A>) : EvalResult<Expr<V, A>, Error, V> {
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
    evalOptions: EvalOptions<Expr<V, A>, EvalError<Expr<V, A>>, V, A>
  ) : ParseEvalResult<Expr<V, A>, ParseError<AnnotatedExpr<V, A>>, EvalError<Expr<V, A>>, V> {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(parseError) : ParseError(parseError);
      case Right(ae) : switch eval(ae.expr, evalOptions) {
        case Left(errors) : EvalErrors(errors);
        case Right(value) : Success(value);
      };
    };
  }
}

class AnnotatedExprEvaluator {
  public static function eval<Error, V, A>(ae : AnnotatedExpr<V, A>, options: EvalOptions<AnnotatedExpr<V, A>, Error, V, A>) : EvalResult<AnnotatedExpr<V, A>, Error, V> {//VNel<{ expr: AnnotatedExpr<V, A>, error: Error }, V> {
    return switch ae.expr {
      case ELit(value) : successNel(value);

      case EVar(name) :
        options.variables.getOption(name).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no variable definition was given for variable: $name', ae) }),
          value -> successNel(value)
        );

      case EFunc(name, argExprs) :
        options.functions.getOption(name).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no function definition was given for function: $name', ae) }),
          func ->
            argExprs.traverseValidation(argExpr -> eval(argExpr, options), Nel.semigroup())
              .flatMapV(argValues -> func(argValues).leftMap(errors -> errors.map(error -> { expr: ae, error: options.onError(error, ae) })))
        );

      case EUnOpPre(operator, precedence, operandExpr) :
        options.unOps.pre.getOption(operator).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no prefix unary operator was given for operator: $operator', ae) }),
          preOp -> eval(operandExpr, options)
            .flatMapV(operandValue -> preOp(operandValue).leftMap(errors -> errors.map(error -> { expr: ae, error: options.onError(error, ae) })))
        );

      case EBinOp(operator, precedence, leftExpr, rightExpr) :
        options.binOps.getOption(operator).cataf(
          () -> failureNel({ expr: ae, error: options.onError('no operator definition was given for operator: $operator', ae) }),
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
    evalOptions: EvalOptions<AnnotatedExpr<V, A>, EvalError<AnnotatedExpr<V, A>>, V, A>
  ) : ParseEvalResult<AnnotatedExpr<V, A>, ParseError<AnnotatedExpr<V, A>>, EvalError<AnnotatedExpr<V, A>>, V> {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(parseError) : ParseError(parseError);
      case Right(ae) : switch eval(ae, evalOptions) {
        case Left(errors) : EvalErrors(errors);
        case Right(value) : Success(value);
      };
    };
  }
}
