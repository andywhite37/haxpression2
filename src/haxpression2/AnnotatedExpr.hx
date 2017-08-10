package haxpression2;

using thx.Arrays;
using thx.Maps;
import thx.Tuple;
import thx.Unit;
import thx.fp.Functions.const;

import haxpression2.Expr;

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

  public static function isAnyLit<V, A>(ae : AnnotatedExpr<V, A>) : Bool {
    return Exprs.isAnyLit(ae.expr);
  }

  public static function mapValue<V1, V2, A>(ae : AnnotatedExpr<V1, A>, f : V1 -> V2) : AnnotatedExpr<V2, A> {
    return new AnnotatedExpr(Exprs.mapValue(ae.expr, f), ae.annotation);
  }

  public static function mapAnnotation<V, A, B>(ae : AnnotatedExpr<V, A>, f : AnnotatedExpr<V, A> -> B) : AnnotatedExpr<V, B> {
    return new AnnotatedExpr(Exprs.mapAnnotation(ae.expr, f), f(ae));
  }

  public static function voidAnnotation<V, A>(ae : AnnotatedExpr<V, A>) : AnnotatedExpr<V, Unit> {
    return mapAnnotation(ae, const(unit));
  }

  public static function getVarsMap<V, A>(ae : AnnotatedExpr<V, A>) : Map<String, Array<A>> {
    function appendVar(vars : Map<String, Array<A>>, name: String, a : A) : Map<String, Array<A>> {
      if (vars.exists(name)) {
        vars.get(name).push(a);
      } else {
        vars.set(name, [a]);
      }
      return vars;
    }
    function mergeVars(vars : Map<String, Array<A>>, others : Map<String, Array<A>>) : Map<String, Array<A>> {
      return others.tuples().reduce(function(vars : Map<String, Array<A>>, otherPair : Tuple<String, Array<A>>) {
        var otherName = otherPair._0;
        var otherMetas = otherPair._1;
        return otherMetas.reduce(function(vars : Map<String, Array<A>>, otherMeta: A) {
          return appendVar(vars, otherName, otherMeta);
        }, vars);
      }, vars);
    }
    function accVars(vars : Map<String, Array<A>>, ae : AnnotatedExpr<V, A>) : Map<String, Array<A>> {
      return switch ae.expr {
        case ELit(_) : vars;
        case EVar(name) : appendVar(vars, name, ae.annotation);
        case EFunc(name, argExprs) :
          argExprs.reduce(function(vars : Map<String, Array<A>>, argExpr : AnnotatedExpr<V, A>) {
            return mergeVars(vars, getVarsMap(argExpr));
          }, vars);
        case EUnOpPre(_, _, operandExpr) : mergeVars(vars, getVarsMap(operandExpr));
        case EBinOp(_, _, leftExpr, rightExpr) :
          var varsWithLeftVars = mergeVars(vars, getVarsMap(leftExpr));
          mergeVars(varsWithLeftVars, getVarsMap(rightExpr));
      }
    }
    return accVars(new Map(), ae);
  }

  public static function getVarsArray<V, A>(ae : AnnotatedExpr<V, A>) : Array<String> {
    return Exprs.getVarsArray(ae.expr);
  }

  public static function substitute<V, A>(target : AnnotatedExpr<V, A>, name : String, sub : AnnotatedExpr<V, A>) : AnnotatedExpr<V, A> {
    return switch target.expr {
      case ELit(_) : target;
      case EVar(n) if (n == name) : sub;
      case EVar(_) : target;
      case EFunc(name, args) : create(EFunc(name, args.map(arg -> substitute(arg, name, sub))), target.annotation);
      case EBinOp(operator, precedence, left, right) : create(EBinOp(operator, precedence, substitute(left, name, sub), substitute(right, name, sub)), target.annotation);
      case EUnOpPre(operator, precedence, operand) : create(EUnOpPre(operator, precedence, substitute(operand, name, sub)), target.annotation);
    };
  }

  public static function substituteMap<V, A>(target : AnnotatedExpr<V, A>, subs : Map<String, AnnotatedExpr<V, A>>) : AnnotatedExpr<V, A> {
    return subs.foldLeftWithKeys(function(target : AnnotatedExpr<V, A>, name : String, sub : AnnotatedExpr<V, A>) {
      return substitute(target, name, sub);
    }, target);
  }
}

typedef AnnotatedExprBinOp<V, A> = AnnotatedExpr<V, A> -> AnnotatedExpr<V, A> -> AnnotatedExpr<V, A>;
typedef AnnotatedExprUnOp<V, A> = AnnotatedExpr<V, A> -> AnnotatedExpr<V, A>;
