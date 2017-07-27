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
  var exprParser : Parser<AnnotatedExpr<Value<Float>, ParseMeta>>;

  public function new() {}

  public function setup() {
    exprParser = ExprParser.create(getOptions()).expr;
  }

  public static function getOptions() : ExprParserOptions<Value<Float>, Float, ParseMeta> {
    return {
      variableNameRegexp: ~/[a-z][a-z0-9]*(?:!?[a-z0-9]+)?/i,
      functionNameRegexp: ~/[a-z]+/i,
      binOps: BinOp.getStandardBinOps(),
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

  function ae<V, A>(expr : Expr<V, A>, a : A) : AnnotatedExpr<V, A> {
    return new AnnotatedExpr(expr, a);
  }

  public function testWhitespaceErrors() {
    assertError("");
    assertError(" ");
    assertError("   ");
    assertError("\t");
    assertError("\t ");
  }

  public function testLitNum() {
    assertExpr("0.0", ELit(VNum(0.0)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr("1.0", ELit(VNum(1.0)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr(" 1.1  ", ELit(VNum(1.1)), new ParseMeta({ offset: 1, line: 1, column: 2 }));
  }

  public function testLitInt() {
    assertExpr("0", ELit(VInt(0)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr("1", ELit(VInt(1)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr(" 1  ", ELit(VInt(1)), new ParseMeta({ offset: 1, line: 1, column: 2 }));
  }

  public function testLitBool() {
    assertExpr("true", ELit(VBool(true)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr("false", ELit(VBool(false)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr("   true ", ELit(VBool(true)), new ParseMeta({ offset: 3, line: 1, column: 4 }));
    assertExpr("  false ", ELit(VBool(false)), new ParseMeta({ offset: 2, line: 1, column: 3 }));
    assertExpr("True", ELit(VBool(true)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr("False", ELit(VBool(false)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr("TRUE", ELit(VBool(true)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
    assertExpr("FALSE", ELit(VBool(false)), new ParseMeta({ offset: 0, line: 1, column: 1 }));
  }

  public function testVar() {
    assertExpr("a", EVar("a"), meta(0, 1, 1));
    assertExpr(" a", EVar("a"), meta(1, 1, 2));
    assertExpr(" a ", EVar("a"), meta(1, 1, 2));
    assertExpr("   a ", EVar("a"), meta(3, 1, 4));
    assertExpr("sales", EVar("sales"), meta(0, 1, 1));
    assertExpr(" sales", EVar("sales"), meta(1, 1, 2));
    assertExpr("   sales ", EVar("sales"), meta(3, 1, 4));
    assertExpr("asn!sales", EVar("asn!sales"), meta(0, 1, 1));
    assertExpr(" asn!sales", EVar("asn!sales"), meta(1, 1, 2));
    assertExpr("   asn!sales ", EVar("asn!sales"), meta(3, 1, 4));
  }

  public function testVarErrors() {
    assertError("x y");
    assertError("!asn");
    assertError("asn!");
    assertError("asn!!sales");
    assertError("asn!sales x");
  }

  public function testFunc() {
    assertExpr("TEST()",
      EFunc("TEST", []),
      meta(0, 1, 1)
    );

    assertExpr(" TEST (   ) ",
      EFunc("TEST", []),
      meta(1, 1, 2)
    );

    assertExpr("TEST(1, true)",
      EFunc("TEST", [
        ae(ELit(VInt(1)), meta(5, 1, 6)),
        ae(ELit(VBool(true)), meta(8, 1, 9))
      ]),
      meta(0, 1, 1)
    );
  }

  public function testBinOp() {
    assertExpr("1+2",
      EBinOp("+",
        ae(ELit(VInt(1)), meta(0, 1, 1)),
        ae(ELit(VInt(2)), meta(2, 1, 3))
      ),
      meta(1, 1, 2)
    );

    assertExpr("(1+2)",
      EBinOp("+",
        ae(ELit(VInt(1)), meta(1, 1, 2)),
        ae(ELit(VInt(2)), meta(3, 1, 4))
      ),
      meta(2, 1, 3)
    );

    assertExpr(" 1  + 2  ",
      EBinOp("+",
        ae(ELit(VInt(1)), meta(1, 1, 2)),
        ae(ELit(VInt(2)), meta(6, 1, 7))
      ),
      meta(4, 1, 5)
    );

    assertExpr("1 + 2 * 3",
      EBinOp(
        "+",
        ae(ELit(VInt(1)), meta(0, 1, 1)),
        ae(
          EBinOp(
            "*",
            ae(ELit(VInt(2)), meta(4, 1, 5)),
            ae(ELit(VInt(3)), meta(8, 1, 9))
          ),
          meta(6, 1, 7)
        )
      ),
      meta(2, 1, 3)
    );

    assertExpr("(1 + 2) * 3",
      EBinOp(
        "*",
        ae(
          EBinOp(
            "+",
            ae(ELit(VInt(1)), meta(1, 1, 2)),
            ae(ELit(VInt(2)), meta(5, 1, 6))
          ),
          meta(3, 1, 4)
        ),
        ae(
          ELit(VInt(3)),
          meta(10, 1, 11)
        )
      ),
      meta(8, 1, 9)
    );

    assertExpr("(1 + (2 + (3 + 4)))",
      EBinOp(
        "+",
        ae(ELit(VInt(1)), meta(1, 1, 2)),
        ae(
          EBinOp(
            "+",
            ae(ELit(VInt(2)), meta(6, 1, 7)),
            ae(
              EBinOp(
                "+",
                ae(ELit(VInt(3)), meta(11, 1, 12)),
                ae(ELit(VInt(4)), meta(15, 1, 16))
              ),
              meta(13, 1, 14)
            )
          ),
          meta(8, 1, 9)
        )
      ),
      meta(3, 1, 4)
    );
  }

  function assertExpr(input : String, expected : Expr<Value<Float>, ParseMeta>, expectedMeta: ParseMeta, ?log : Bool, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, getOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) :
        if (log) {
          trace(input);
          trace(actual.toString(v -> Values.toString(v, Std.string), a -> a.toString()));
        }
        Assert.same(new AnnotatedExpr(expected, expectedMeta), actual, pos);
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
