package haxpression2.parse;

import utest.Assert;

using Parsihax;

import thx.Eithers;

import haxpression2.Value;
import haxpression2.parse.ValueParser;

class TestValueParser {
  var valueParser : Parser<Value<Float>>;

  public function new() {}

  public function setup() {
    valueParser = ValueParser.create(getOptions()).value;
  }

  function getOptions() : ValueParserOptions<Float> {
    return {
      parseDecimal: Std.parseFloat
    };
  }

  public function testValueNA() : Void {
    Assert.same(VNA, valueParser.apply("NA").value);
    Assert.same(VNA, valueParser.apply("na").value);
    Assert.same(VNA, valueParser.apply("Na").value);
    Assert.same(VNA, valueParser.apply("nA").value);
  }

  public function testValueNM() : Void {
    Assert.same(VNM, valueParser.apply("NM").value);
    Assert.same(VNM, valueParser.apply("nm").value);
    Assert.same(VNM, valueParser.apply("Nm").value);
    Assert.same(VNM, valueParser.apply("nM").value);
  }

  public function testValueInt() : Void {
    Assert.same(VInt(0), valueParser.apply("0").value);
    Assert.same(VInt(1), valueParser.apply("1").value);
    Assert.same(VInt(-1), valueParser.apply("-1").value);
    Assert.same(VInt(1234556), valueParser.apply("1234556").value);
  }

  public function testValueNum() : Void {
    Assert.same(VNum(0.0), valueParser.apply("0.0").value);
    Assert.same(VNum(1.0), valueParser.apply("1.0").value);
    Assert.same(VNum(1.1), valueParser.apply("1.1").value);
  }

  public function testValueBool() : Void {
    Assert.same(VBool(true), valueParser.apply("true").value);
    Assert.same(VBool(true), valueParser.apply("TRUE").value);
    Assert.same(VBool(false), valueParser.apply("false").value);
    Assert.same(VBool(false), valueParser.apply("FALSE").value);
  }

  public function testValueString() : Void {
    Assert.same(VStr("hi"), valueParser.apply("\"hi\"").value);
    Assert.same(VStr("hi"), valueParser.apply("'hi'").value);
    Assert.same(VStr("hi, \"guy\""), valueParser.apply("'hi, \"guy\"'").value);
  }

  public function testError() : Void {
    Assert.isTrue(Eithers.isLeft(ValueParser.parseString("x", TestHelper.getTestParserOptions())));
    Assert.isTrue(Eithers.isLeft(ValueParser.parseString("0.1.1", TestHelper.getTestParserOptions())));
  }
}
