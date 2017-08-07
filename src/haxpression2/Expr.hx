package haxpression2;

import Parsihax;

using thx.Arrays;
import thx.Functions.identity;
using thx.Maps;
import thx.Nel;
using thx.Options;
using thx.Strings;
import thx.Validation;
import thx.Validation.*;

/**
 *  Expression AST
 */
enum Expr<V, A> {
  ELit(value : V);
  EVar(name : String);
  EFunc(func : String, args : Array<AnnotatedExpr<V, A>>);
  EUnOpPre(operator : String, precedence: Int, expr : AnnotatedExpr<V, A>);
  //EUnOpPost(operator : String, expr : AnnotatedExpr<V, A>);
  EBinOp(operator : String, precedence: Int, left : AnnotatedExpr<V, A>, right : AnnotatedExpr<V, A>);
}

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

/**
 *  Helper class for dealing with `Expr<V, A>`
 */
class Exprs {
  /**
   *  Converts an expression to a canonical string
   *
   *  @param expr - Expression to print
   *  @param valueToString - Function to convert the `V` value type to `String`
   *  @return String
   */
  public static function toString<V, A>(expr : Expr<V, A>, valueToString : V -> String) : String {
    return switch expr {
      case ELit(value) : valueToString(value);

      case EVar(name) : name;

      case EFunc(name, argExprs) :
        var argsStr = argExprs.map(argExpr -> toString(argExpr.expr, valueToString)).join(", ");
        '${name}(${argsStr})';

      case EUnOpPre(operator, precedence, operandExpr) :
        '${operator}${toString(operandExpr.expr, valueToString)}';

      case EBinOp(operator, precedence, leftExpr, rightExpr) :
        var leftStr = toString(leftExpr.expr, valueToString);
        var leftStrSafe = switch leftExpr.expr {
          case EBinOp(_, lprecedence, _, _) if (lprecedence < precedence) :
            // if a left-side bin op has lower precendence, parenthesize it
            '($leftStr)';
          case _ :
            '$leftStr';
        };
        var rightStr = toString(rightExpr.expr, valueToString);
        var rightStrSafe = switch rightExpr.expr {
          case EBinOp(_, rprecedence, _, _) if (rprecedence < precedence) :
            // if a right-side bin op has lower precendence, parenthesize it
            '($rightStr)';
          case _ :
            '$rightStr';
        };
        '$leftStrSafe $operator $rightStrSafe';
    }
  }

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

  public static function isVar<V, A>(expr : Expr<V, A>, name : String) : Bool {
    return switch expr {
      case EVar(exprName) if (exprName == name) : true;
      case _ : false;
    };
  }

  public static function mapValue<V1, V2, A>(expr : Expr<V1, A>, f : V1 -> V2) : Expr<V2, A> {
    return switch expr {
      case ELit(v) : ELit(f(v));
      case EVar(name) : EVar(name);
      case EFunc(name, args) : EFunc(name, args.map(arg -> AnnotatedExpr.mapValue(arg, f)));
      case EUnOpPre(operator, precedence, operandExpr) : EUnOpPre(operator, precedence, AnnotatedExpr.mapValue(operandExpr, f));
      case EBinOp(operator, precedence, leftExpr, rightExpr) : EBinOp(operator, precedence, AnnotatedExpr.mapValue(leftExpr, f), AnnotatedExpr.mapValue(rightExpr, f));
    }
  }

  public static function mapAnnotation<V, A, B>(expr : Expr<V, A>, f : Expr<V, A> -> A -> B) : Expr<V, B> {
    return switch expr {
      case ELit(value) : ELit(value);
      case EVar(name) : EVar(name);
      case EFunc(name, argExprs) : EFunc(name, argExprs.map(argExpr -> AnnotatedExpr.mapAnnotation(argExpr, f)));
      case EUnOpPre(operator, precedence, operandExpr) : EUnOpPre(operator, precedence, AnnotatedExpr.mapAnnotation(operandExpr, f));
      case EBinOp(operator, precedence, leftExpr, rightExpr) : EBinOp(operator, precedence, AnnotatedExpr.mapAnnotation(leftExpr, f), AnnotatedExpr.mapAnnotation(rightExpr, f));
    };
  }
}

class AnnotatedExpr<V, A> {
  public var expr(default, null) : Expr<V, A>;
  public var annotation(default, null) : A;

  public function new(expr : Expr<V, A>, annotation : A) {
    this.expr = expr;
    this.annotation = annotation;
  }

  public static function ae<V, A>(expr : Expr<V, A>, annotation : A) : AnnotatedExpr<V, A> {
    return new AnnotatedExpr(expr, annotation);
  }

  public static function toString<V, A>(ae : AnnotatedExpr<V, A>, valueToString : V -> String, annotationToString : A -> String, ?depth = 0) : String {
    var indent = "  ".repeat(depth);
    return switch ae.expr {
      case e = ELit(v) :
        '${Exprs.toString(e, valueToString)} ${annotationToString(ae.annotation)}';

      case e = EVar(name) :
        '${Exprs.toString(e, valueToString)} ${annotationToString(ae.annotation)}';

      case e = EFunc(name, argExprs) :
        var argStrings = argExprs.map(argExpr -> toString(argExpr, valueToString, annotationToString, depth + 1)).join('\n$indent');
'${Exprs.toString(e, valueToString)}
$argStrings';

      case e = EUnOpPre(operator, precendece, operandExpr) :
        var operandString = toString(operandExpr, valueToString, annotationToString, depth + 1);
'${Exprs.toString(e, valueToString)}
${indent}${operator} ${annotationToString(ae.annotation)}
${indent}  Operand: $operandString';

      case e = EBinOp(op, prec, left, right) :
        var leftString = toString(left, valueToString, annotationToString, depth + 1);
        var rightString = toString(right, valueToString, annotationToString, depth + 1);
'${Exprs.toString(e, valueToString)}
${indent}${op} (prec: ${prec}) ${annotationToString(ae.annotation)}
${indent}  Left: $leftString
${indent}  Right: $rightString';
    };
  }

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

  public static function mapValue<V1, V2, A>(ae : AnnotatedExpr<V1, A>, f : V1 -> V2) : AnnotatedExpr<V2, A> {
    return new AnnotatedExpr(Exprs.mapValue(ae.expr, f), ae.annotation);
  }

  public static function mapAnnotation<V, A, B>(ae : AnnotatedExpr<V, A>, f : Expr<V, A> -> A -> B) : AnnotatedExpr<V, B> {
    return new AnnotatedExpr(Exprs.mapAnnotation(ae.expr, f), f(ae.expr, ae.annotation));
  }
}

typedef AnnotatedExprBinOp<V, A> = AnnotatedExpr<V, A> -> AnnotatedExpr<V, A> -> AnnotatedExpr<V, A>;
typedef AnnotatedExprUnOp<V, A> = AnnotatedExpr<V, A> -> AnnotatedExpr<V, A>;
