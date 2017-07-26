package haxpression2;

import thx.Either;

import utest.Assert;

import parsihax.Parser.*;
using parsihax.Parser;

import haxpression2.CoreParser as C;
import haxpression2.ParseMeta.meta;
import haxpression2.Value;
import haxpression2.ValueParser;

class TestValueParser {
  public function new() {}

  function getOptions() : ValueParserOptions<Float, ParseMeta> {
    return {
      convertFloat: thx.Functions.identity,
      meta: ParseMeta.new
    };
  }

  public function testValueInt() : Void {
    Assert.same(VInt(0, meta(0)), ValueParser.valueInt(getOptions()).apply("0").value);
    Assert.same(VInt(1, meta(0)), ValueParser.valueInt(getOptions()).apply("1").value);
    Assert.same(VInt(-1, meta(0)), ValueParser.valueInt(getOptions()).apply("-1").value);
    Assert.same(VInt(1234556, meta(0)), ValueParser.valueInt(getOptions()).apply("1234556").value);
  }

  public function testValueBool() : Void {
    Assert.same(VBool(true, meta(0)), ValueParser.valueBool(getOptions()).apply("true").value);
    Assert.same(VBool(false, meta(0)), ValueParser.valueBool(getOptions()).apply("false").value);
  }

  public function testValue_Ints() : Void {
    Assert.same(VInt(0, meta(0)), ValueParser.value(getOptions()).apply("0").value);
    Assert.same(VInt(1, meta(0)), ValueParser.value(getOptions()).apply("1").value);
  }

  public function testValue_Nums() : Void {
    Assert.same(VNum(0.0, meta(0)), ValueParser.value(getOptions()).apply("0.0").value);
    Assert.same(VNum(1.0, meta(0)), ValueParser.value(getOptions()).apply("1.0").value);
    Assert.same(VNum(1.1, meta(0)), ValueParser.value(getOptions()).apply("1.1").value);
  }

  public function testValue_Bools() : Void {
    Assert.same(VBool(true, meta(0)), ValueParser.value(getOptions()).apply("true").value);
    Assert.same(VBool(false, meta(0)), ValueParser.value(getOptions()).apply("false").value);
  }

  public function testValue_Strings() : Void {
    Assert.same(VStr("hi", meta(0)), ValueParser.value(getOptions()).apply("\"hi\"").value);
    Assert.same(VStr("hi", meta(0)), ValueParser.value(getOptions()).apply("'hi'").value);
    Assert.same(VStr("hi, \"guy\"", meta(0)), ValueParser.value(getOptions()).apply("'hi, \"guy\"'").value);
  }

  public function assertInt(input : String, expected : Int, index: Int, ?pos : haxe.PosInfos) : Void {
    switch ValueParser.parse(input, getOptions()) {
      case Left(error) : Assert.fail(error.toString(), pos);
      case Right(actual) : Assert.same(VInt(expected, meta(index)), pos);
    }
  }

  public function assertBool(input : String, expected : Bool, index: Int, ?pos : haxe.PosInfos) : Void {
    switch ValueParser.parse(input, getOptions()) {
      case Left(error) : Assert.fail(error.toString(), pos);
      case Right(actual) : Assert.same(VBool(expected, meta(index)), pos);
    }
  }
}
