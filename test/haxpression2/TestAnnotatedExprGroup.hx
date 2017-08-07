package haxpression2;

import TestHelper;
import haxpression2.simple.FloatExpr;

class TestAnnotatedExprGroup {
  public function new() {}

  public function testExprGroup() {
    var group = AnnotatedExprGroup.parseMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + b",
    ], TestHelper.getTestParserOptions())
    .map(group -> group.render(FloatExprs.renderValue))
    .map(val -> trace(val));
  }
}
