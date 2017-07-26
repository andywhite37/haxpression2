package haxpression2;

using thx.Arrays;
import thx.Either;
using thx.Eithers;

import utest.Assert;

import parsihax.Parser.*;
using parsihax.Parser;

import haxpression2.CoreParser as C;
using haxpression2.Expr;
import haxpression2.ExprParser;
import haxpression2.ParseMeta.meta;
using haxpression2.Value;
import haxpression2.ValueParser;

class TestExprParser {
  public function new() {}

  public function testX() {
    Assert.pass();
  }

  static function getOptions() : ExprParserOptions<Value<Float, ParseMeta>, Float, ParseMeta> {
    return {
      variableNameRegexp: ~/[a-z][a-z0-9]*(?:!?[a-z0-9]+)?/i,
      functionNameRegexp: ~/[a-z]+/i,
      binOps: [
      ],
      unOps: {
        pre: [
        ],
        post: [
        ]
      },
      convertFloat: thx.Functions.identity,
      convertValue: thx.Functions.identity,
      meta: ParseMeta.new
    };
  }

  public function testWhitespace_Errors() {
    assertError("");
    assertError(" ");
    assertError("   ");
    assertError("\t");
    assertError("\t ");
  }

  public function testLiteralInts() {
    assertLit("1", ELit(VInt(1, meta(0)), meta(0)));
  }

  public function testVariables() {
    assertVar("a", "a", 0);
    assertVar(" a", "a", 1);
    assertVar(" a ", "a", 1);
    assertVar("   a ", "a", 3);
    assertVar("sales", "sales", 0);
    assertVar(" sales", "sales", 1);
    assertVar("   sales ", "sales", 3);
    assertVar("asn!sales", "asn!sales", 0);
    assertVar(" asn!sales", "asn!sales", 1);
    assertVar("   asn!sales ", "asn!sales", 3);
    assertVar("asn!sales", "asn!sales", 0);
  }

  public function testVariables_Errors() {
    assertError("asn!!sales");
    assertError("asn!sales x");
  }

  public function xtestBinOp_Simple() {
    assertExpr("1+2",
      EBinOp("+",
        ELit(VInt(1, meta(0)), meta(0)),
        ELit(VInt(2, meta(4)), meta(4)),
        meta(0)
      )
    );
  }

  public function testBinary() : Void {
    var result = sepBy(C.integer, "+".string())
      .map(function(ints : Array<Int>) {
        return EBinOp("+",
          ELit(VInt(ints[0], meta(0)), meta(0)),
          ELit(VInt(ints[1], meta(0)), meta(0)),
          meta(0)
        );
      })
      .apply("1+2*3");
    trace(result);
  }

  function assertExpr(input : String, expected : Expr<Value<Float, ParseMeta>, ParseMeta>, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, getOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) : Assert.same(expected, actual, pos);
    }
  }

  function assertLit(input : String, expected : Expr<Value<Float, ParseMeta>, ParseMeta>, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, getOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) : Assert.same(expected, actual);
    };
  }

  function assertVar(input : String, name : String, index : Int, ?pos : haxe.PosInfos) : Void {
    assertExpr(input, EVar(name, new ParseMeta(index)), pos);
  }

  function assertError(input : String, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, getOptions()) {
      case Left(parseError) : Assert.pass(pos);
      case Right(_) : Assert.fail('$input should not have parsed', pos);
    };
  }
}
