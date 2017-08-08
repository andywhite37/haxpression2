package haxpression2;

import utest.Assert;

import haxpression2.simple.SimpleExpr;
import haxpression2.simple.SimpleValue;

import TestHelper;

class TestAnnotatedExprGroup {
  public function new() {}

  public function testExprGroup() {
    AnnotatedExprGroup.parseStringToStringMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + b",
    ], TestHelper.getTestParserOptions())
    .map(group -> group.renderString(SimpleValues.renderString))
    .map(groupString -> Assert.same("a: 1\nb: 2\nc: a + b", groupString));
  }
}
