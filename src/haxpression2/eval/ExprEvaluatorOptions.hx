package haxpression2.eval;

import thx.Nel;
import thx.Validation;

/**
 * Function for evaluating a unary operator expression (VNel allows for failures)
 */
typedef ExprEvaluatorUnOp<V> = {
  eval: V -> VNel<String, V>
};

/**
 * Function for evaluating a binary operator expression (VNel allows for failures)
 */
typedef ExprEvaluatorBinOp<V> = {
  eval: V -> V -> VNel<String, V>
};

/**
 * Function for evaluating a function expression (VNel allows for failures)
 */
typedef ExprEvaluatorFunc<V> = {
  arity: ExprEvaluatorFuncArity,
  eval: Array<V> -> VNel<String, V>
};

enum ExprEvaluatorFuncArity {
  Fixed(args : Int);
  Range(argsMin : Int, argsMax: Int);
  Variable;
}

/**
 * Structure for caller to supply values for variables, and definitions for functions and operators
 * for use in an evaluation.
 */
typedef ExprEvaluatorOptions<TExpr, TError, V> = {
  onError: String -> TExpr -> TError,
  variables: Map<String, V>,
  unOps: {
    pre: Map<String, ExprEvaluatorUnOp<V>>,
    post: Map<String, ExprEvaluatorUnOp<V>>
  },
  binOps: Map<String, ExprEvaluatorBinOp<V>>,
  functions: Map<String, ExprEvaluatorFunc<V>>
};

typedef ExprEvaluatorResult<TExpr, TError, V> = VNel<{ expr: TExpr, error: TError }, V>;

enum ExprStringEvaluatorResult<TExpr, TParseError, TEvalError, V> {
  ParseError(error : TParseError);
  EvalErrors(errors : Nel<{ expr: TExpr, error: TEvalError }>);
  Evaluated(value : V);
}
