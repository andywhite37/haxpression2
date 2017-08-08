package haxpression2.parse;

import utest.Assert;

using Parsihax;

import thx.Eithers;

import haxpression2.Value;
import haxpression2.parse.ValueParser;

import TestHelper.assertParseValue;
import TestHelper.assertParseValueError;

class TestValueParser {
  public function new() {}

  public function testValueNA() : Void {
    assertParseValue(VNA, "NA");
    assertParseValue(VNA, "na");
    assertParseValue(VNA, "Na");
    assertParseValue(VNA, "nA");
  }

  public function testValueNM() : Void {
    assertParseValue(VNM, "NM");
    assertParseValue(VNM, "nm");
    assertParseValue(VNM, "Nm");
    assertParseValue(VNM, "nM");
  }

  public function testValueInt() : Void {
    assertParseValue(VInt(0), "0");
    assertParseValue(VInt(1), "1");
    assertParseValue(VInt(-1), "-1");
    assertParseValue(VInt(1234556), "1234556");
  }

  public function testValueNum() : Void {
    assertParseValue(VNum(0.0), "0.0");
    assertParseValue(VNum(1.0), "1.0");
    assertParseValue(VNum(1.1), "1.1");
  }

  public function testValueBool() : Void {
    assertParseValue(VBool(true), "true");
    assertParseValue(VBool(true), "TRUE");
    assertParseValue(VBool(false), "false");
    assertParseValue(VBool(false), "FALSE");
  }

  public function testValueString() : Void {
    assertParseValue(VStr("hi"), "\"hi\"");
    assertParseValue(VStr("hi"), "'hi'");
    assertParseValue(VStr("hi, \"guy\""), "'hi, \"guy\"'");
  }

  public function testError() : Void {
    assertParseValueError("");
    assertParseValueError(" ");
    assertParseValueError("x");
    assertParseValueError("0.1.1");
  }
}
