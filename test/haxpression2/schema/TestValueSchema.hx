package haxpression2.schema;

import utest.Assert;

using thx.schema.SchemaDynamicExtensions;
import thx.schema.SimpleSchema.*;

import haxpression2.Expr;
import haxpression2.Value;
import haxpression2.schema.ExprSchema;

class TestValueSchema {
  public function new() {}

  public function testRenderDynamic() : Void {
    Assert.same({
      "VNA": {}
    }, ValueSchema.schema(float()).renderDynamic(VNA));

    Assert.same({
      "VNM": {}
    }, ValueSchema.schema(float()).renderDynamic(VNM));

    Assert.same({
      "VInt": 0
    }, ValueSchema.schema(float()).renderDynamic(VInt(0)));

    Assert.same({
      "VInt": 123
    }, ValueSchema.schema(float()).renderDynamic(VInt(123)));

    Assert.same({
      "VNum": 0.0
    }, ValueSchema.schema(float()).renderDynamic(VNum(0.0)));

    Assert.same({
      "VNum": 123.1
    }, ValueSchema.schema(float()).renderDynamic(VNum(123.1)));

    Assert.same({
      "VBool": true
    }, ValueSchema.schema(float()).renderDynamic(VBool(true)));

    Assert.same({
      "VBool": false
    }, ValueSchema.schema(float()).renderDynamic(VBool(false)));

    Assert.same({
      "VStr": ""
    }, ValueSchema.schema(float()).renderDynamic(VStr("")));

    Assert.same({
      "VStr": "hi"
    }, ValueSchema.schema(float()).renderDynamic(VStr("hi")));
  }
}
