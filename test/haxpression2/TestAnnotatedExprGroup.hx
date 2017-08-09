package haxpression2;

import utest.Assert;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

using haxpression2.AnnotatedExprGroup;
import haxpression2.parse.ParseMeta;
import haxpression2.schema.AnnotatedExprSchema;
import haxpression2.schema.ExprSchema;
import haxpression2.schema.ParseMetaSchema;
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
    .map(group -> AnnotatedExprGroup.renderString(group, SimpleValueRenderer.renderString, ParseMeta.renderString))
    .map(groupString -> Assert.same("a: 1\nb: 2\nc: a + b", groupString));
  }

  public function testExpand<E, V, A>() : Void {
    AnnotatedExprGroup.parseStringMap([
      "a" => "1",
      "b" => "2",
      "c" => "a + e",
      "d" => "a + c + 6 + x + b",
      "e" => "44 / 10 + a"
    ], TestHelper.getTestParserOptions())
    .map(group -> {
      trace('original:\n${AnnotatedExprGroup.renderString(group, SimpleValueRenderer.renderString, ParseMeta.renderString)}');
      return group;
    })
    .map(group -> group.expand())
    .map(group -> {
      var metaSchema : Schema<E, ExpandMeta<SimpleValue, ParseMeta>>;

      metaSchema = lazy(() ->
        ExpandMeta.schema(
          AnnotatedExprSchema.schema(SimpleValueSchema.schema(), ParseMetaSchema.schema()),
          ExprSchema.schema(SimpleValueSchema.schema(), metaSchema)
        ).schema
      );

      return {
        plain: AnnotatedExprGroup.renderString(group, SimpleValueRenderer.renderString, ExpandMeta.renderString),
        json: AnnotatedExprGroup.renderJSONString(
          group,
          SimpleValueSchema.schema(),
          metaSchema
        )
      };
    })
    .map(data -> {
      trace('expanded (plain):\n${data.plain}');

      trace('expanded (JSON):\n${data.json}');
    });
  }
}
