package haxpression2;

import utest.Assert;

using thx.Iterators;
using thx.Options;
import thx.Unit;
import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

using haxpression2.AnnotatedExprGroup;
import haxpression2.parse.ParseMeta;
using haxpression2.render.SchemaJSONRenderer;
import haxpression2.schema.AnnotatedExprSchema;
import haxpression2.schema.ExprSchema;
import haxpression2.schema.ParseMetaSchema;
using haxpression2.simple.SimpleExpr;
import haxpression2.simple.SimpleValue;

import TestHelper;

class TestAnnotatedExprGroup {
  public function new() {}

  public function testRenderPlainString() {
    AnnotatedExprGroup.parseStringMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + b",
    ], TestHelper.getTestExprParserOptions({ annotate: ParseMeta.new }))
    .map(group -> SimpleAnnotatedExprGroup.renderPlainString(group, SimpleValueRenderer.renderString, ParseMeta.renderString))
    .map(groupString -> Assert.same("a:\n  1\nb:\n  2\nc:\n  a + b", groupString));
  }

  public function testExpand1() : Void {
    AnnotatedExprGroup.parseStringMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + e",
      "d" => "a + c + 6 + x + b",
      "e" => "44 / 10 + a",
      "x" => "y * z"
    ], TestHelper.getTestExprParserOptions({ annotate: _ -> unit }))
    .map(group -> group.expand())
    .map(group -> {
      Assert.same("1", group.getVar("a").get().expr.renderString());
      Assert.same("2", group.getVar("b").get().expr.renderString());
      Assert.same("1 + 44 / 10 + 1", group.getVar("c").get().expr.renderString());
      Assert.same("1 + 1 + 44 / 10 + 1 + 6 + y * z + 2", group.getVar("d").get().expr.renderString());
      Assert.same("44 / 10 + 1", group.getVar("e").get().expr.renderString());
      Assert.same("y * z", group.getVar("x").get().expr.renderString());
    });
  }

  public function testAnalyze1() : Void {
    AnnotatedExprGroup.parseStringMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + e",
      "d" => "a + c + 6 + x + b",
      "e" => "44 / 10 + a",
      "x" => "y * z"
    ], TestHelper.getTestExprParserOptions({ annotate: _ -> unit }))
    .map(group -> group.analyze(SimpleValueRenderer.renderString))
    .map(result -> {
      //TestHelper.traceAnalyzeResult(result);
      Assert.same(["a", "b", "c", "d", "e", "x", "y", "z"], result.allVars);
      Assert.same(["y", "z"], result.externalVars);
      Assert.same(["a", "b", "c", "d", "e", "x"], result.definedVars);
      Assert.same(["e", "z", "y", "x", "d", "c", "b", "a"], result.dependencySortedVars);
      Assert.same(6, result.analyzedExprs.keys().toArray().length);
    });
  }

  public function testExpand2() : Void {
    AnnotatedExprGroup.parseStringMap([
      "a" => "b + x",
      "b" => "c + y",
      "c" => "d + e",
      "d" => "x + y + z",
      "e" => "123"
    ], TestHelper.getTestExprParserOptions({ annotate: _ -> unit }))
    .map(group -> group.expand())
    .map(group -> {
      Assert.same(5, group.getVarCount());
      Assert.same("x + y + z + 123 + y + x", group.getVar("a").get().expr.renderString());
      Assert.same("x + y + z + 123 + y", group.getVar("b").get().expr.renderString());
      Assert.same("x + y + z + 123", group.getVar("c").get().expr.renderString());
      Assert.same("x + y + z", group.getVar("d").get().expr.renderString());
      Assert.same("123", group.getVar("e").get().expr.renderString());
    });
  }

  public function testAnalyze2() : Void {
    AnnotatedExprGroup.parseStringMap([
      "a" => "b + x",
      "b" => "c + y",
      "c" => "d + e",
      "d" => "x + y + z",
      "e" => "123"
    ], TestHelper.getTestExprParserOptions({ annotate: _ -> unit }))
    .map(group -> group.analyze(SimpleValueRenderer.renderString))
    .map(result -> {
      //TestHelper.traceAnalyzeResult(result);
      Assert.same(5, result.analyzedExprs.keys().toArray().length);
      Assert.same(["a", "b", "c", "d", "e", "x", "y", "z"], result.allVars);
      Assert.same(["x", "y", "z"], result.externalVars);
      Assert.same(["a", "b", "c", "d", "e"], result.definedVars);
      Assert.same(["e", "z", "y", "x", "d", "c", "b", "a"], result.dependencySortedVars);
    });
  }
}
