package haxpression2;

class BinOp {
  public var operator(default, null) : String;
  public var precedence(default, null) : Int;

  public function new(operator, precedence) {
    this.operator = operator;
    this.precedence = precedence;
  }

  public static function getStandardBinOps() : Array<BinOp> {
    return [
      new BinOp("-", 6),
      new BinOp("+", 6),
      new BinOp("/", 7),
      new BinOp("*", 7),
    ];
  }
}
