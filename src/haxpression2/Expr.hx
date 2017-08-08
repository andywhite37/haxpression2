package haxpression2;

using thx.Arrays;
using thx.Maps;
import thx.Tuple;

/**
 *  Expression AST
 */
enum Expr<V, A> {
  ELit(value : V);
  EVar(name : String);
  EFunc(func : String, argExprs : Array<AnnotatedExpr<V, A>>);
  EUnOpPre(operator : String, precedence: Int, operandExpr : AnnotatedExpr<V, A>);
  //EUnOpPost(operator : String, expr : AnnotatedExpr<V, A>);
  EBinOp(operator : String, precedence: Int, leftExpr : AnnotatedExpr<V, A>, rightExpr : AnnotatedExpr<V, A>);
}

/**
 *  Helper class for dealing with `Expr<V, A>`
 */
class Exprs {
  public static function isVar<V, A>(expr : Expr<V, A>, name : String) : Bool {
    return switch expr {
      case EVar(exprName) if (exprName == name) : true;
      case _ : false;
    };
  }

  public static function getVars<V, A>(expr : Expr<V, A>) : Array<String> {
    function accVars(acc: Array<String>, expr : Expr<V, A>) : Array<String> {
      return switch expr {
        case ELit(_) : acc;
        case EVar(name) : acc.concat([name]);
        case EFunc(name, argExprs) : acc.concat(argExprs.map(ae -> ae.expr).flatMap(getVars));
        case EUnOpPre(_, _, operandExpr) : acc.concat(getVars(operandExpr.expr));
        case EBinOp(_, _, leftExpr, rightExpr) : acc.concat(getVars(leftExpr.expr)).concat(getVars(rightExpr.expr));
      };
    }
    return accVars([], expr).distinct();
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
