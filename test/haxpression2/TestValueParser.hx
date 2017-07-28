package haxpression2;

import thx.Either;

import utest.Assert;

import Parsihax.*;
using Parsihax;

import haxpression2.CoreParser as C;
import haxpression2.ParseMeta;
import haxpression2.Value;
import haxpression2.ValueParser;

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

  public function testValueNum() : Void {
    Assert.same(VNum(0.0), valueParser.apply("0.0").value);
    Assert.same(VNum(1.0), valueParser.apply("1.0").value);
    Assert.same(VNum(1.1), valueParser.apply("1.1").value);
  }

  public function testValueInt() : Void {
    Assert.same(VInt(0), valueParser.apply("0").value);
    Assert.same(VInt(1), valueParser.apply("1").value);
    Assert.same(VInt(-1), valueParser.apply("-1").value);
    Assert.same(VInt(1234556), valueParser.apply("1234556").value);
  }

  public function testValueBool() : Void {
    Assert.same(VBool(true), valueParser.apply("true").value);
    Assert.same(VBool(false), valueParser.apply("false").value);
  }

  public function testValueString() : Void {
    Assert.same(VStr("hi"), valueParser.apply("\"hi\"").value);
    Assert.same(VStr("hi"), valueParser.apply("'hi'").value);
    Assert.same(VStr("hi, \"guy\""), valueParser.apply("'hi, \"guy\"'").value);
  }
}
