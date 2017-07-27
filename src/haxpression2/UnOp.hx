package haxpression2;

class UnOp {
  public var operatorRegexp(default, null) : EReg;
  public var precedence(default, null) : Int;

  public function new(operatorRegexp, precedence) {
    this.operatorRegexp = operatorRegexp;
    this.precedence = precedence;
  }
}
