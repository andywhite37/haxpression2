package haxpression2;

// N type arg allows for storing numbers in any type that can be converted to from a Float (e.g. thx.Decimal)
enum Value<N> {
  VNA;
  VNM;
  VInt(value : Int);
  VReal(value : N);
  VStr(value : String);
  VBool(value : Bool);
}

class Values {
  public static var NA_STR = "NA";
  public static var NM_STR = "NM";

  public static inline function na<N>() : Value<N> {
    return VNA;
  }

  public static inline function nm<N>() : Value<N> {
    return VNM;
  }

  public static inline function int<N>(v : Int) : Value<N> {
    return VInt(v);
  }

  public static inline function real<N>(v : N) : Value<N> {
    return VReal(v);
  }

  public static inline function str<N>(v : String) : Value<N> {
    return VStr(v);
  }

  public static inline function bool<N>(v : Bool) : Value<N> {
    return VBool(v);
  }
}
