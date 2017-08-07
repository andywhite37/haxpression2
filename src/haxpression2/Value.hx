package haxpression2;

// N type arg allows for storing numbers in any type that can be converted to from a Float (e.g. thx.Decimal)
enum Value<N> {
  VNA;
  VNM;
  VInt(value : Int);
  VNum(value : N);
  VStr(value : String);
  VBool(value : Bool);
}

class Values {
  public static var NA_STR = "NA";
  public static var NM_STR = "NM";

  public static function renderString<N>(value : Value<N>, nToString : N -> String) : String {
    return switch value {
      case VNA: NA_STR;
      case VNM: NM_STR;
      case VInt(v) : Std.string(v);
      case VNum(v) : nToString(v);
      case VStr(v) : '"$v"';
      case VBool(v) : v ? "true" : "false";
    }
  }

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
