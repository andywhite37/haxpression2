package haxpression2;

class BinOp {
  public var operatorRegexp(default, null) : EReg;
  public var precedence(default, null) : Int;

  public function new(operator, precedence) {
    this.operatorRegexp = operator;
    this.precedence = precedence;
  }
}
