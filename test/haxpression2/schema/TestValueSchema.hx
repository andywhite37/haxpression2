package haxpression2.schema;

import utest.Assert;

import thx.Either;
import thx.Functions.identity;
using thx.schema.SchemaDynamicExtensions;

import haxpression2.simple.SimpleValue;

class TestValueSchema {
  public function new() {}

  public function testRenderDynamic() : Void {
    Assert.same({
      "VNA": {}
    }, SimpleValueSchema.schema().renderDynamic(VNA));

    Assert.same({
      "VNM": {}
    }, SimpleValueSchema.schema().renderDynamic(VNM));

    Assert.same({
      "VInt": 0
    }, SimpleValueSchema.schema().renderDynamic(VInt(0)));

    Assert.same({
      "VInt": 123
    }, SimpleValueSchema.schema().renderDynamic(VInt(123)));

    Assert.same({
      "VNum": 0.0
    }, SimpleValueSchema.schema().renderDynamic(VNum(0.0)));

    Assert.same({
      "VNum": 123.1
    }, SimpleValueSchema.schema().renderDynamic(VNum(123.1)));

    Assert.same({
      "VBool": true
    }, SimpleValueSchema.schema().renderDynamic(VBool(true)));

    Assert.same({
      "VBool": false
    }, SimpleValueSchema.schema().renderDynamic(VBool(false)));

    Assert.same({
      "VStr": ""
    }, SimpleValueSchema.schema().renderDynamic(VStr("")));

    Assert.same({
      "VStr": "hi"
    }, SimpleValueSchema.schema().renderDynamic(VStr("hi")));
  }

  public function testParseDynamic() : Void {
    Assert.same(
      Right(VNA),
      SimpleValueSchema.schema().parseDynamic(identity, { VNA: {} })
    );

    Assert.same(
      Right(VNM),
      SimpleValueSchema.schema().parseDynamic(identity, { VNM: {} })
    );

    Assert.same(
      Right(VInt(123)),
      SimpleValueSchema.schema().parseDynamic(identity, { VInt: 123 })
    );

    Assert.same(
      Right(VNum(123.1)),
      SimpleValueSchema.schema().parseDynamic(identity, { VNum: 123.1 })
    );

    Assert.same(
      Right(VBool(true)),
      SimpleValueSchema.schema().parseDynamic(identity, { VBool: true })
    );

    Assert.same(
      Right(VBool(false)),
      SimpleValueSchema.schema().parseDynamic(identity, { VBool: false })
    );

    Assert.same(
      Right(VStr("")),
      SimpleValueSchema.schema().parseDynamic(identity, { VStr: "" })
    );
  }
}
