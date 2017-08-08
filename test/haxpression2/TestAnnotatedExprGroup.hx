package haxpression2;

import utest.Assert;

import haxpression2.simple.FloatExpr;

import TestHelper;

class TestAnnotatedExprGroup {
  public function new() {}

  public function testExprGroup() {
    AnnotatedExprGroup.parseMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + b",
    ], TestHelper.getTestParserOptions())
    .map(group -> group.render(FloatExprs.renderValue))
    .map(groupString -> Assert.same("a: 1\nb: 2\nc: a + b", groupString));
  }
}
