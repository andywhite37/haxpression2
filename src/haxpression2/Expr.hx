package haxpression2;

using thx.Arrays;
using thx.Strings;
import haxpression2.Value;

//enum Expr<V, I, F, B, A> {
enum Expr<V, A> {
  ELit(value : V);
  EVar(name : String);
  EFunc(func : String, args : Array<AnnotatedExpr<V, A>>);
  //EUnOpPre(operator : String, expr : AnnotatedExpr<V, A>);
  //EUnOpPost(operator : String, expr : AnnotatedExpr<V, A>);
  EBinOp(operator : String, left : AnnotatedExpr<V, A>, right : AnnotatedExpr<V, A>);
  //ECond(test : Expr<V, A>, consequent : Expr<V, A>, alternate : Expr<V, A>, a : A);
}

class Exprs {
  public static function toString<V, A>(expr : Expr<V, A>, valueToString : V -> String) : String {
    return switch expr {
      case ELit(value) : valueToString(value);
      case EVar(name) : name;
      case EFunc(name, args) : name + "(" + args.map(arg -> toString(arg.expr, valueToString)).join(", ") + ")";
      case EBinOp(op, left, right) : "(" + toString(left.expr, valueToString) + " " + op + " " + toString(right.expr, valueToString) + ")";
    }
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
      case EBinOp(op, left, right) : EBinOp(op, AnnotatedExpr.mapValue(left, f), AnnotatedExpr.mapValue(right, f));
    }
  }

  public static function mapAnnotation<V, A, B>(expr : Expr<V, A>, f : Expr<V, A> -> A -> B) : Expr<V, B> {
    return switch expr {
      case ELit(value) : ELit(value);
      case EVar(name) : EVar(name);
      case EFunc(name, args) : EFunc(name, args.map(arg -> AnnotatedExpr.mapAnnotation(arg, f)));
      case EBinOp(op, left, right) : EBinOp(op, AnnotatedExpr.mapAnnotation(left, f), AnnotatedExpr.mapAnnotation(right, f));
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

  public static function toString<V, A>(ae : AnnotatedExpr<V, A>, valueToString : V -> String, annotationToString : A -> String, ?depth = 0) : String {
    var indent = "  ".repeat(depth);
    return switch ae.expr {
      case e = ELit(v) : '${Exprs.toString(e, valueToString)} ${annotationToString(ae.annotation)}';
      case e = EVar(name) : '${Exprs.toString(e, valueToString)} ${annotationToString(ae.annotation)}';
      case e = EFunc(name, args) :
        var argStrings = args.map(arg -> toString(arg, valueToString, annotationToString, depth + 1)).join('\n$indent');
        '${Exprs.toString(e, valueToString)}\n$argStrings';
      case e = EBinOp(op, left, right) :
        var leftString = toString(left, valueToString, annotationToString, depth + 1);
        var rightString = toString(right, valueToString, annotationToString, depth + 1);
        '${Exprs.toString(e, valueToString)}\n${indent}${op} ${annotationToString(ae.annotation)}\n${indent}  Left: $leftString\n${indent}  Right: $rightString';
    };
    //return Exprs.toString(ae.expr, valueToString) + '\n\n  ' + annotationToString(ae.annotation);
  }

  public static function mapValue<V1, V2, A>(ae : AnnotatedExpr<V1, A>, f : V1 -> V2) : AnnotatedExpr<V2, A> {
    return new AnnotatedExpr(Exprs.mapValue(ae.expr, f), ae.annotation);
  }

  public static function mapAnnotation<V, A, B>(ae : AnnotatedExpr<V, A>, f : Expr<V, A> -> A -> B) : AnnotatedExpr<V, B> {
    return new AnnotatedExpr(Exprs.mapAnnotation(ae.expr, f), f(ae.expr, ae.annotation));
  }
}

typedef AnnotatedExprBinOp<V, A> = AnnotatedExpr<V, A> -> AnnotatedExpr<V, A> -> AnnotatedExpr<V, A>;
