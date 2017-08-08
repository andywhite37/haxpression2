package haxpression2.schema;

import utest.Assert;

import thx.schema.SimpleSchema.*;
using thx.schema.SchemaDynamicExtensions;

import haxpression2.AnnotatedExpr;
import haxpression2.AnnotatedExpr.create as ae;
import haxpression2.Value;
import haxpression2.parse.ParseMeta;
import haxpression2.parse.ParseMeta.create as meta;

class TestAnnotatedExprSchema {
  public function new() {}

  public static function assertRenderDynamic(expected : Dynamic, ae : AnnotatedExpr<Value<Float>, ParseMeta>, ?pos : haxe.PosInfos) : Void {
    var valueSchema = ValueSchema.schema(float());
    var metaSchema = ParseMetaSchema.schema();
    Assert.same(
      expected,
      AnnotatedExprSchema.schema(valueSchema, metaSchema).renderDynamic(ae),
      pos
    );
  }

  public function testRenderDynamic() : Void {
    assertRenderDynamic({
      expr: {
        EFunc: {
          name: "myFunc",
          args: ([
            {
              expr: { ELit: { VInt: 1 } },
              annotation: { index: { offset: 1, line: 2, column: 2 } }
            },
            {
              expr: { EVar: "a" },
              annotation: { index: { offset: 3, line: 4, column: 4 } }
            }
          ] : Array<Dynamic>)
        }
      },
      annotation: { index: { offset: 0, line: 1, column: 1 } }
    },
    ae(
      EFunc("myFunc", [
        ae(
          ELit(VInt(1)),
          meta(1, 2, 2)
        ),
        ae(
          EVar("a"),
          meta(3, 4, 4)
        ),
      ]),
      meta(0, 1, 1)
    ));
  }
}
