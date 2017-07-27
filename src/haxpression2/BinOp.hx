package haxpression2;

class BinOp {
  public var operatorRegexp(default, null) : EReg;
  public var precedence(default, null) : Int;

  public function new(operator, precedence) {
    this.operatorRegexp = operator;
    this.precedence = precedence;
  }

  public static function getStandardBinOps() : Array<BinOp> {
    return [
      new BinOp(~/\+|-/, 6), // + or -
      new BinOp(~/\*|\//, 7), // * or /
    ];
  }
}
