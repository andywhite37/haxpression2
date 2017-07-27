package haxpression2;

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
  //EUnOpPre(operator : String, expr : AnnotatedExpr<V, A>);
  //EUnOpPost(operator : String, expr : AnnotatedExpr<V, A>);
  EBinOp(operator : String, precedence: Int, left : AnnotatedExpr<V, A>, right : AnnotatedExpr<V, A>);
  //ECond(test : Expr<V, A>, consequent : Expr<V, A>, alternate : Expr<V, A>, a : A);
}

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
typedef EvalOptions<V> = {
  variables: Map<String, V>,
  binOps: Map<String, EvalBinOp<V>>,
  functions: Map<String, EvalFunc<V>>
};

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

      case EFunc(name, args) :
        var argsStr = args.map(arg -> toString(arg.expr, valueToString)).join(", ");
        '${name}(${argsStr})';

      case EBinOp(op, prec, left, right) :
        // if a left-side bin op has lower precendence, parenthesize it
        var leftStr = toString(left.expr, valueToString);
        var leftStrSafe = switch left.expr {
          case EBinOp(_, lprec, _, _) if (lprec < prec) :
            '($leftStr)';
          case _ :
            '$leftStr';
        };
        // if a right-side bin op has lower precendence, parenthesize it
        var rightStr = toString(right.expr, valueToString);
        var rightStrSafe = switch right.expr {
          case EBinOp(_, rprec, _, _) if (rprec < prec) :
            '($rightStr)';
          case _ :
            '$rightStr';
        };
        '$leftStrSafe $op $rightStrSafe';
    }
  }

  public static function eval<V, A>(expr : Expr<V, A>, options: EvalOptions<V>) : VNel<String, V> {
    return switch expr {
      case ELit(value) : successNel(value);

      case EVar(name) :
        options.variables.getOption(name).cataf(
          () -> failureNel('no variable definition was given for variable: $name'),
          value -> successNel(value)
        );

      case EFunc(name, args) :
        options.functions.getOption(name).cataf(
          () -> failureNel('no function definition was given for function: $name'),
          func ->
            args.traverseValidation(arg -> eval(arg.expr, options), Nel.semigroup())
              .flatMapV(values -> func(values))
        );

      case EBinOp(op, prec, left, right) :
        options.binOps.getOption(op).cataf(
          () -> failureNel('no operator definition was given for operator: $op'),
          func -> val2(
            func,
            eval(left.expr, options),
            eval(right.expr, options),
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
      case EBinOp(op, prec, left, right) : EBinOp(op, prec, AnnotatedExpr.mapValue(left, f), AnnotatedExpr.mapValue(right, f));
    }
  }

  public static function mapAnnotation<V, A, B>(expr : Expr<V, A>, f : Expr<V, A> -> A -> B) : Expr<V, B> {
    return switch expr {
      case ELit(value) : ELit(value);
      case EVar(name) : EVar(name);
      case EFunc(name, args) : EFunc(name, args.map(arg -> AnnotatedExpr.mapAnnotation(arg, f)));
      case EBinOp(op, prec, left, right) : EBinOp(op, prec, AnnotatedExpr.mapAnnotation(left, f), AnnotatedExpr.mapAnnotation(right, f));
    };
  }
}

class AnnotatedExpr<V, A> {
  public var expr(default, null) : Expr<V, A>;
  public var annotation(default, null) : A;

  public function new(expr, annotation) {
    this.expr = expr;
    this.annotation = annotation;
  }

  public static function ae<V, A>(expr : Expr<V, A>, a : A) : AnnotatedExpr<V, A> {
    return new AnnotatedExpr(expr, a);
  }

  public static function toString<V, A>(ae : AnnotatedExpr<V, A>, valueToString : V -> String, annotationToString : A -> String, ?depth = 0) : String {
    var indent = "  ".repeat(depth);
    return switch ae.expr {
      case e = ELit(v) :
        '${Exprs.toString(e, valueToString)} ${annotationToString(ae.annotation)}';

      case e = EVar(name) :
        '${Exprs.toString(e, valueToString)} ${annotationToString(ae.annotation)}';

      case e = EFunc(name, args) :
        var argStrings = args.map(arg -> toString(arg, valueToString, annotationToString, depth + 1)).join('\n$indent');
'${Exprs.toString(e, valueToString)}
$argStrings';

      case e = EBinOp(op, prec, left, right) :
        var leftString = toString(left, valueToString, annotationToString, depth + 1);
        var rightString = toString(right, valueToString, annotationToString, depth + 1);
'${Exprs.toString(e, valueToString)}
${indent}${op} (prec: ${prec}) ${annotationToString(ae.annotation)}
${indent}  Left: $leftString
${indent}  Right: $rightString';
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
