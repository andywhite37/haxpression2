package haxpression2;

enum Expr<V, A> {
  ELit(value : V, a : A);
  EVar(name : String, a : A);
  EUnOpPre(operator : String, expr : Expr<V, A>, a : A);
  EUnOpPost(operator : String, expr : Expr<V, A>, a : A);
  EBinOp(operator : String, left : Expr<V, A>, right : Expr<V, A>, a : A);
  EFunc(func : String, args : Array<Expr<V, A>>, a : A);
  //ECond(test : Expr<V, A>, consequent : Expr<V, A>, alternate : Expr<V, A>, a : A);
}

class Exprs {
  public static function isVar<V, A>(expr : Expr<V, A>, name : String) : Bool {
    return switch expr {
      case EVar(exprName, _) if (exprName == name) : true;
      case _ : false;
    };
  }
}
