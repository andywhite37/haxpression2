package haxpression2;

import utest.Assert;

using thx.Iterators;
using thx.Options;
import thx.Unit;
import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
using thx.schema.SchemaDynamicExtensions;

import haxpression2.AnnotatedExpr.create as ae;
using haxpression2.AnnotatedExprGroup;
import haxpression2.parse.ParseMeta;
import haxpression2.parse.ParseMeta.create as meta;
using haxpression2.render.SchemaJSONRenderer;
import haxpression2.schema.AnnotatedExprSchema;
import haxpression2.schema.AnnotatedExprGroupSchema;
import haxpression2.schema.ExprSchema;
import haxpression2.schema.ParseMetaSchema;
using haxpression2.simple.SimpleExpr;
import haxpression2.simple.SimpleValue;

import TestHelper;

class TestAnnotatedExprGroup {
  public function new() {}

  public function testParseFallbackStringsMap() : Void {
    var map : Map<String, Array<String>> = [
      "a" => ["b + c", "123"],
      "b" => ["d", "e"],
      "c" => ["NA", "123"]
    ];
    var expected = new AnnotatedExprGroup([
      "a$0" => ae(
        EBinOp(
          "+",
          6,
          ae(
            EVar("b"),
            meta(0, 1, 1)
          ),
          ae(
            EVar("c"),
            meta(4, 1, 5)
          )
        ),
        meta(2, 1, 3)
      ),
      "a$1" => ae(
        ELit(VInt(123)),
        meta(0, 1, 1)
      ),
      "a" => ae(
        EFunc("COALESCE", [
          ae(
            EVar("a$0"),
            meta(9, 1, 10)
          ),
          ae(
            EVar("a$1"),
            meta(14, 1, 15)
          )
        ]),
        meta(0, 1, 1)
      ),
      "b$0" => ae(
        EVar("d"),
        meta(0, 1, 1)
      ),
      "b$1" => ae(
        EVar("e"),
        meta(0, 1, 1)
      ),
      "b" => ae(
        EFunc("COALESCE", [
          ae(
            EVar("b$0"),
            meta(9, 1, 10)
          ),
          ae(
            EVar("b$1"),
            meta(14, 1, 15)
          )
        ]),
        meta(0, 1, 1)
      ),
      "c$0" => ae(
        ELit(VNA),
        meta(0, 1, 1)
      ),
      "c$1" => ae(
        ELit(VInt(123)),
        meta(0, 1, 1)
      ),
      "c" => ae(
        EFunc("COALESCE", [
          ae(
            EVar("c$0"),
            meta(9, 1, 10)
          ),
          ae(
            EVar("c$1"),
            meta(14, 1, 15)
          )
        ]),
        meta(0, 1, 1)
      )
    ]);
    switch AnnotatedExprGroup.parseFallbackStringsMap(map, "COALESCE", (key, index) -> '$key$$$index', TestHelper.getTestExprParserOptions({ annotate: ParseMeta.new })) {
      case Left(errors) : Assert.fail(errors.toArray().map(e -> e.toString()).join("\n"));
      case Right(actual) :
        //var raw : {} = AnnotatedExprGroupSchema.schema(SimpleValueSchema.schema(), ParseMetaSchema.schema()).renderDynamic(actual);
        //var pretty = haxe.Json.stringify(raw, null, '  ');
        //trace(pretty);
        Assert.same(expected, actual);
    };
  }

  public function testRenderPlainString() : Void {
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
