package haxpression2.schema;

import utest.Assert;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema.*;
using thx.schema.SchemaDynamicExtensions;

import haxpression2.AnnotatedExpr.create as ae;
import haxpression2.Expr;
import haxpression2.Value;
import haxpression2.parse.ParseMeta;
import haxpression2.parse.ParseMeta.create as meta;
import haxpression2.schema.ExprSchema;

class TestExprSchema {
  public function new() {}

  public function assertRenderDynamic<V, A>(expected : Dynamic, expr : Expr<Value<Float>, ParseMeta>, ?pos : haxe.PosInfos) : Void {
    var valueSchema = ValueSchema.schema(float());
    var metaSchema = ParseMetaSchema.schema();
    Assert.same(expected, ExprSchema.schema(valueSchema, metaSchema).renderDynamic(expr));
  }

  public function testRenderDynamicEVar() : Void {
    assertRenderDynamic({
      EVar: "test"
    }, EVar("test"));
  }

  public function testRenderDynamicELit() : Void {
    assertRenderDynamic({
      ELit: {
        VInt: 123
      }
    }, ELit(VInt(123)));

    assertRenderDynamic({
      ELit: {
        VNum: 123.1
      }
    }, ELit(VNum(123.1)));

    assertRenderDynamic({
      ELit: {
        VBool: true
      }
    }, ELit(VBool(true)));

    assertRenderDynamic({
      ELit: {
        VBool: false
      }
    }, ELit(VBool(false)));

    assertRenderDynamic({
      ELit: {
        VStr: ""
      }
    }, ELit(VStr("")));
  }

  public function testRenderDynamicEFunc() : Void {
    assertRenderDynamic(
      {
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
      EFunc("myFunc", [
        ae(
          ELit(VInt(1)),
          meta(1, 2, 2)
        ),
        ae(
          EVar("a"),
          meta(3, 4, 4)
        ),
      ])
    );
  }

  public function testRenderDynamicEBinOp() : Void {
    assertRenderDynamic(
      {
        EBinOp: {
          operator: "+",
          precedence: 5,
          left: {
            expr: {
              EVar: "a"
            },
            annotation: { index: { offset: 1, line: 2, column: 3 } }
          },
          right: {
            expr: {
              EVar: "b"
            },
            annotation: { index: { offset: 4, line: 5, column: 6 } }
          }
        }
      },
      EBinOp(
        "+",
        5,
        ae(EVar("a"), meta(1, 2, 3)),
        ae(EVar("b"), meta(4, 5, 6))
      )
    );
  }

  public function testRenderDynamicEUnOpPre() : Void {
    assertRenderDynamic(
      {
        EUnOpPre: {
          operator: "~",
          precedence: 5,
          operand: {
            expr: {
              EVar: "a"
            },
            annotation: { index: { offset: 1, line: 2, column: 3 } }
          }
        }
      },
      EUnOpPre(
        "~",
        5,
        ae(EVar("a"), meta(1, 2, 3))
      )
    );
  }
}
