package haxpression2.schema;

import haxe.ds.Option;

import utest.Assert;

import thx.Either;
using thx.Eithers;
import thx.Functions.identity;
using thx.Options;
import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema.*;
using thx.schema.SchemaDynamicExtensions;

import haxpression2.AnnotatedExpr.create as ae;
import haxpression2.Expr;
import haxpression2.Value;
import haxpression2.parse.ParseMeta;
import haxpression2.parse.ParseMeta.create as meta;
import haxpression2.schema.ExprSchema;
import haxpression2.simple.SimpleExpr;

class TestExprSchema {
  public function new() {}

  public function assertRenderDynamic<V, A>(expected : Dynamic, expr : Expr<Value<Float>, ParseMeta>, ?pos : haxe.PosInfos) : Void {
    var valueSchema = ValueSchema.schema(float());
    var metaSchema = ParseMetaSchema.schema();
    Assert.same(expected, ExprSchema.schema(valueSchema, metaSchema).renderDynamic(expr));
  }

  public function testRenderDynamicEVar() : Void {
    assertRenderDynamic({
      "var": "test"
    }, EVar("test"));
  }

  public function testRenderDynamicELit() : Void {
    assertRenderDynamic({
      lit: {
        int: 123
      }
    }, ELit(VInt(123)));

    assertRenderDynamic({
      lit: {
        real: 123.1
      }
    }, ELit(VReal(123.1)));

    assertRenderDynamic({
      lit: {
        bool: true
      }
    }, ELit(VBool(true)));

    assertRenderDynamic({
      lit: {
        bool: false
      }
    }, ELit(VBool(false)));

    assertRenderDynamic({
      lit: {
        string: ""
      }
    }, ELit(VStr("")));
  }

  public function testRenderDynamicEFunc() : Void {
    assertRenderDynamic(
      {
        func: {
          name: "myFunc",
          args: ([
            {
              expr: { lit: { int: 1 } },
              annotation: { index: { offset: 1, line: 2, column: 2 } }
            },
            {
              expr: { "var": "a" },
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
        binOp: {
          operator: "+",
          precedence: 5,
          left: {
            expr: {
              "var": "a"
            },
            annotation: { index: { offset: 1, line: 2, column: 3 } }
          },
          right: {
            expr: {
              "var": "b"
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
        unOpPre: {
          operator: "~",
          precedence: 5,
          operand: {
            expr: {
              "var": "a"
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

  public function testRoundTrip() : Void {
    var input = "1+ 2 + a  /b+ func ( true  ,   'hi' ) - sin(cos(x)/atan2(y), false) * ((a + b) / 3)  ";

    // Parse string
    SimpleExprParser.parseString(input, SimpleExprs.getStandardExprParserOptions({ annotate: ParseMeta.new }))
      .toRight()
      .map(function(ae : SimpleAnnotatedExpr<ParseMeta>) : Dynamic {
        // Render Dynamic
        return SimpleAnnotatedExprSchema.schema().renderDynamic(ae);
      })
      .flatMap(function(data : Dynamic) : Option<SimpleAnnotatedExpr<ParseMeta>> {
        // Parse Dynamic
        return SimpleAnnotatedExprSchema.schema().parseDynamic(identity, data).either.toRight();
      })
      .map(function(ae : SimpleAnnotatedExpr<ParseMeta>) : String {
        // Render back to string
        return SimpleExprRenderer.renderString(ae.expr);
      })
      .each(function(str : String) : Void {
        Assert.same('1 + 2 + a / b + func(true, "hi") - sin(cos(x) / atan2(y), false) * (a + b) / 3', str);
      });
  }
}
