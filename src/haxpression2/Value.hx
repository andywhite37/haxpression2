package haxpression2;

enum Value<N, A> {
  VInt(value : Int, a : A);
  VNum(value : N, a : A);
  VStr(value : String, a : A);
  VBool(value : Bool, a : A);
}

class Values {
  public static function int<N, A>(v : Int, a : A) : Value<N, A> {
    return VInt(v, a);
  }
}
