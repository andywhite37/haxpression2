package haxpression2.parse;

class ExprParserBinOp {
  public var operatorRegexp(default, null) : EReg;
  public var precedence(default, null) : Int;

  public function new(operator, precedence) {
    this.operatorRegexp = operator;
    this.precedence = precedence;
  }
}
