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
      "NA": {}
    }, SimpleValueSchema.schema().renderDynamic(VNA));

    Assert.same({
      "NM": {}
    }, SimpleValueSchema.schema().renderDynamic(VNM));

    Assert.same({
      "int": 0
    }, SimpleValueSchema.schema().renderDynamic(VInt(0)));

    Assert.same({
      "int": 123
    }, SimpleValueSchema.schema().renderDynamic(VInt(123)));

    Assert.same({
      "real": 0.0
    }, SimpleValueSchema.schema().renderDynamic(VReal(0.0)));

    Assert.same({
      "real": 123.1
    }, SimpleValueSchema.schema().renderDynamic(VReal(123.1)));

    Assert.same({
      "bool": true
    }, SimpleValueSchema.schema().renderDynamic(VBool(true)));

    Assert.same({
      "bool": false
    }, SimpleValueSchema.schema().renderDynamic(VBool(false)));

    Assert.same({
      "string": ""
    }, SimpleValueSchema.schema().renderDynamic(VStr("")));

    Assert.same({
      "string": "hi"
    }, SimpleValueSchema.schema().renderDynamic(VStr("hi")));
  }

  public function testParseDynamic() : Void {
    Assert.same(
      Right(VNA),
      SimpleValueSchema.schema().parseDynamic(identity, { NA: {} })
    );

    Assert.same(
      Right(VNM),
      SimpleValueSchema.schema().parseDynamic(identity, { NM: {} })
    );

    Assert.same(
      Right(VInt(123)),
      SimpleValueSchema.schema().parseDynamic(identity, { int: 123 })
    );

    Assert.same(
      Right(VReal(123.1)),
      SimpleValueSchema.schema().parseDynamic(identity, { real: 123.1 })
    );

    Assert.same(
      Right(VBool(true)),
      SimpleValueSchema.schema().parseDynamic(identity, { bool: true })
    );

    Assert.same(
      Right(VBool(false)),
      SimpleValueSchema.schema().parseDynamic(identity, { bool: false })
    );

    Assert.same(
      Right(VStr("")),
      SimpleValueSchema.schema().parseDynamic(identity, { string: "" })
    );
  }
}
