package haxpression2;

using thx.Arrays;
import thx.Either;
using thx.Eithers;

import utest.Assert;

import Parsihax.*;
using Parsihax;

import haxpression2.CoreParser as C;
using haxpression2.Expr;
import haxpression2.ExprParser;
import haxpression2.ParseMeta;
import haxpression2.ParseMeta.meta;
using haxpression2.Value;
import haxpression2.ValueParser;

class TestExprParser {
  var exprParser : Parser<Expr<Value<Float>, ParseMeta>>;

  public function new() {}

  public function setup() {
    exprParser = ExprParser.create(getOptions()).expr;
  }

  static function getOptions() : ExprParserOptions<Value<Float>, Float, ParseMeta> {
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

  public function testWhitespaceErrors() {
    assertError("");
    assertError(" ");
    assertError("   ");
    assertError("\t");
    assertError("\t ");
  }

  public function testLitNum() {
    assertExpr("0.0", ELit(VNum(0.0), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertExpr("1.0", ELit(VNum(1.0), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertExpr(" 1.1  ", ELit(VNum(1.1), new ParseMeta({ offset: 1, line: 1, column: 2 })));
  }

  public function testLitInt() {
    assertExpr("0", ELit(VInt(0), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertExpr("1", ELit(VInt(1), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertExpr(" 1  ", ELit(VInt(1), new ParseMeta({ offset: 1, line: 1, column: 2 })));
  }

  public function testVar() {
    assertExpr("a", EVar("a", meta(0, 1, 1)));
    assertExpr(" a", EVar("a", meta(1, 1, 2)));
    assertExpr(" a ", EVar("a", meta(1, 1, 2)));
    assertExpr("   a ", EVar("a", meta(3, 1, 4)));
    assertExpr("sales", EVar("sales", meta(0, 1, 1)));
    assertExpr(" sales", EVar("sales", meta(1, 1, 2)));
    assertExpr("   sales ", EVar("sales", meta(3, 1, 4)));
    assertExpr("asn!sales", EVar("asn!sales", meta(0, 1, 1)));
    assertExpr(" asn!sales", EVar("asn!sales", meta(1, 1, 2)));
    assertExpr("   asn!sales ", EVar("asn!sales", meta(3, 1, 4)));
  }

  public function testVarErrors() {
    assertError("!asn");
    assertError("asn!");
    assertError("asn!!sales");
    assertError("asn!sales x");
  }

  public function testBinOp() {
    assertExpr("1+2",
      EBinOp("+",
        ELit(VInt(1), meta(0, 1, 1)),
        ELit(VInt(2), meta(2, 1, 3)),
        meta(1, 1, 2)
      )
    );

    assertExpr(" 1  + 2  ",
      EBinOp("+",
        ELit(VInt(1), meta(1, 1, 2)),
        ELit(VInt(2), meta(6, 1, 7)),
        meta(4, 1, 5)
      )
    );
  }

  function assertExpr(input : String, expected : Expr<Value<Float>, ParseMeta>, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, getOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) : Assert.same(expected, actual, pos);
    }
  }

/*
  function assertLit(input : String, expected : Expr<Value<Float>, ParseMeta>, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, getOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) : Assert.same(expected, actual);
    };
  }

  function assertVar(input : String, name : String, meta : ParseMeta, ?pos : haxe.PosInfos) : Void {
    assertExpr(input, EVar(name, meta), pos);
  }
  */

  function assertError(input : String, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, getOptions()) {
      case Left(parseError) : Assert.pass(pos);
      case Right(_) : Assert.fail('$input should not have parsed', pos);
    };
  }
}
