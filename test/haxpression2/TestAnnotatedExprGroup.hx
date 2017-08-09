package haxpression2;

import utest.Assert;

using haxpression2.AnnotatedExprGroup;
import haxpression2.simple.SimpleExpr;
import haxpression2.simple.SimpleValue;

import TestHelper;

class TestAnnotatedExprGroup {
  public function new() {}

  public function testExprGroup() {
    AnnotatedExprGroup.parseStringMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + b",
    ], TestHelper.getTestParserOptions())
    .map(group -> AnnotatedExprGroup.renderString(group, SimpleValueRenderer.renderString))
    .map(groupString -> Assert.same("a: 1\nb: 2\nc: a + b", groupString));
  }

  public function testExpand() : Void {
    AnnotatedExprGroup.parseStringMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + b",
    ], TestHelper.getTestParserOptions())
    .map(group -> group.expand())
    .map(group -> trace(SimpleAnnotatedExprGroups.renderString(group)));
  }
}
