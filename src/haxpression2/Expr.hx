package haxpression2;

import Parsihax;

using thx.Arrays;
import thx.Functions.identity;
using thx.Iterators;
using thx.Maps;
import thx.Nel;
using thx.Options;
using thx.Strings;
import thx.Tuple;
import thx.Validation;
import thx.Validation.*;

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

class AnnotatedExpr<V, A> {
  public var expr(default, null) : Expr<V, A>;
  public var annotation(default, null) : A;

  public function new(expr : Expr<V, A>, annotation : A) {
    this.expr = expr;
    this.annotation = annotation;
  }

  public static function create<V, A>(expr : Expr<V, A>, annotation : A) : AnnotatedExpr<V, A> {
    return new AnnotatedExpr(expr, annotation);
  }

  public static function getVars<V, A>(ae : AnnotatedExpr<V, A>) : Map<String, Array<A>> {
    function appendVar(vars : Map<String, Array<A>>, name: String, a : A) : Map<String, Array<A>> {
      if (vars.exists(name)) {
        vars.get(name).push(a);
      } else {
        vars.set(name, [a]);
      }
      return vars;
    }
    function mergeVars(vars : Map<String, Array<A>>, others : Map<String, Array<A>>) : Map<String, Array<A>> {
      return others.tuples().reduce(function(vars : Map<String, Array<A>>, nameMetas : Tuple<String, Array<A>>) {
        var name = nameMetas._0;
        var metas = nameMetas._1;
        return metas.reduce(function(vars : Map<String, Array<A>>, a: A) {
          return appendVar(vars, name, a);
        }, vars);
      }, vars);
    }
    function accVars(vars : Map<String, Array<A>>, ae : AnnotatedExpr<V, A>) : Map<String, Array<A>> {
      return switch ae.expr {
        case ELit(_) : vars;
        case EVar(name) : appendVar(vars, name, ae.annotation);
        case EFunc(name, argExprs) :
          argExprs.reduce(function(vars : Map<String, Array<A>>, argExpr : AnnotatedExpr<V, A>) {
            return mergeVars(vars, getVars(argExpr));
          }, vars);
        case EUnOpPre(_, _, operandExpr) : mergeVars(vars, getVars(operandExpr));
        case EBinOp(_, _, leftExpr, rightExpr) : mergeVars(mergeVars(vars, getVars(leftExpr)), getVars(rightExpr));
      }
    }
    return accVars(new Map(), ae);
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
