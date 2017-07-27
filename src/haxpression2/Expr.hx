package haxpression2;

//enum Expr<V, I, F, B, A> {
enum Expr<V, A> {
  ELit(value : V, a : A);
  EVar(name : String, a : A);
  EFunc(func : String, args : Array<Expr<V, A>>, a : A);
  EUnOpPre(operator : String, expr : Expr<V, A>, a : A);
  EUnOpPost(operator : String, expr : Expr<V, A>, a : A);
  EBinOp(operator : String, left : Expr<V, A>, right : Expr<V, A>, a : A);
  //ECond(test : Expr<V, A>, consequent : Expr<V, A>, alternate : Expr<V, A>, a : A);
}

//enum ExprA<V, A> = { expr: Expr<V>, annotation: A };

class Exprs {
  public static function isVar<V, A>(expr : Expr<V, A>, name : String) : Bool {
    return switch expr {
      case EVar(exprName, _) if (exprName == name) : true;
      case _ : false;
    };
  }

/*
  public static function map<V, A, B>(expr : Expr<V, A>, f : A -> B) : Expr<V, B> {
    return switch expr {
      case ELit(value, a) : ELit(value, f(a));
      case EVar(name, a) : EVar(name, f(a));
      case EFunc(name, args, a) : EFunc(name, args.map(arg -> map(arg, f)), f(a));
      case EBinOp(op, l, r, a) : EBinOp(op, map(l, f), map(r, f), f(a));
      case EUnOpPre(op, expr, a) : EUnOpPre(op, map(expr, f), f(a));
      case EUnOpPost(op, expr, a) : EUnOpPost(op, map(expr, f), f(a));
    };
  }

  public static function flatMap<V, A, B>(expr : Expr<V, A>, f : A -> Expr<V, B>) : Expr<V, B> {
    return switch expr {
      case ELit(value, a) : f(a);
    };
  }
  */
}
