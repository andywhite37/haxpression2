package haxpression2;

enum Value<N> {
  VInt(value : Int);
  VNum(value : N);
  VStr(value : String);
  VBool(value : Bool);
}

class Values {
  public static function int<N>(v : Int) : Value<N> {
    return VInt(v);
  }

  public static function num<N>(v : N) : Value<N> {
    return VNum(v);
  }

  public static function str<N>(v : String) : Value<N> {
    return VStr(v);
  }

  public static function bool<N>(v : Bool) : Value<N> {
    return VBool(v);
  }
}
