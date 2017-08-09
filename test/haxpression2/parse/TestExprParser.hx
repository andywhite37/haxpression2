package haxpression2.parse;

import utest.Assert;

using Parsihax;

import haxpression2.AnnotatedExpr.create as ae;
using haxpression2.Value;
import haxpression2.parse.ParseMeta.create as meta;
import haxpression2.simple.SimpleExpr;

import TestHelper.assertParseString;
import TestHelper.assertParseStringError;

class TestExprParser {
  public function new() {}

  public function testWhitespaceErrors() : Void {
    assertParseStringError("");
    assertParseStringError(" ");
    assertParseStringError("   ");
    assertParseStringError("\t");
    assertParseStringError("\t ");
    assertParseStringError("()");
    assertParseStringError("( )");
    assertParseStringError(",");
  }

  public function testLitNANM() : Void {
    assertParseString("NA", ae(ELit(VNA), meta(0, 1, 1)));
    assertParseString("na", ae(ELit(VNA), meta(0, 1, 1)));
    assertParseString("Na", ae(ELit(VNA), meta(0, 1, 1)));
    assertParseString("nA", ae(ELit(VNA), meta(0, 1, 1)));
    assertParseString("NM", ae(ELit(VNM), meta(0, 1, 1)));
    assertParseString("nm", ae(ELit(VNM), meta(0, 1, 1)));
    assertParseString("Nm", ae(ELit(VNM), meta(0, 1, 1)));
    assertParseString("nM", ae(ELit(VNM), meta(0, 1, 1)));
    assertParseString(
      "NA + NM",
      ae(
        EBinOp(
          "+",
          6,
          ae(ELit(VNA), meta(0, 1, 1)),
          ae(ELit(VNM), meta(5, 1, 6))
        ),
        meta(3, 1, 4)
      )
    );
  }

  public function testLitInt() : Void {
    assertParseString("0", ae(ELit(VInt(0)), meta(0, 1, 1)));
    assertParseString("1", ae(ELit(VInt(1)), meta(0, 1, 1)));
    assertParseString(" 1  ", ae(ELit(VInt(1)), meta(1, 1, 2)));
    assertParseString(" -1  ",
      ae(
        EUnOpPre(
          "-",
          2,
          ae(
            ELit(VInt(1)),
            meta(2, 1, 3)
          )
        ),
        meta(1, 1, 2)
      )
    );
  }

  public function testLitNum() {
    assertParseString("0.0", ae(ELit(VNum(0.0)), meta(0, 1, 1)));
    assertParseString("1.0", ae(ELit(VNum(1.0)), meta(0, 1, 1)));
    assertParseString(" 1.1  ", ae(ELit(VNum(1.1)), meta(1, 1, 2)));
  }

  public function testLitBool() {
    assertParseString("true", ae(ELit(VBool(true)), meta(0, 1, 1)));
    assertParseString("false", ae(ELit(VBool(false)), meta(0, 1, 1)));
    assertParseString("   true ", ae(ELit(VBool(true)), meta(3, 1, 4)));
    assertParseString("  false ", ae(ELit(VBool(false)), meta(2, 1, 3)));
    assertParseString("True", ae(ELit(VBool(true)), meta(0, 1, 1)));
    assertParseString("False", ae(ELit(VBool(false)), meta(0, 1, 1)));
    assertParseString("TRUE", ae(ELit(VBool(true)), meta(0, 1, 1)));
    assertParseString("FALSE", ae(ELit(VBool(false)), meta(0, 1, 1)));
  }

  public function testVar() {
    assertParseString("a", ae(EVar("a"), meta(0, 1, 1)));
    assertParseString(" a", ae(EVar("a"), meta(1, 1, 2)));
    assertParseString(" a ", ae(EVar("a"), meta(1, 1, 2)));
    assertParseString("   a ", ae(EVar("a"), meta(3, 1, 4)));
    assertParseString("sales", ae(EVar("sales"), meta(0, 1, 1)));
    assertParseString(" sales", ae(EVar("sales"), meta(1, 1, 2)));
    assertParseString("   sales ", ae(EVar("sales"), meta(3, 1, 4)));
    assertParseString("asn!sales", ae(EVar("asn!sales"), meta(0, 1, 1)));
    assertParseString(" asn!sales", ae(EVar("asn!sales"), meta(1, 1, 2)));
    assertParseString("   asn!sales ", ae(EVar("asn!sales"), meta(3, 1, 4)));
  }

  public function testVarErrors() {
    assertParseStringError("x y");
    assertParseStringError("!asn");
    assertParseStringError("asn!");
    assertParseStringError("asn!!sales");
    assertParseStringError("asn!sales x");
  }

  public function testFunc() {
    assertParseString("TEST()",
      ae(
        EFunc("TEST", []),
        meta(0, 1, 1)
      )
    );

    assertParseString(" TEST (   ) ",
      ae(
        EFunc("TEST", []),
        meta(1, 1, 2)
      )
    );

    assertParseString("TEST(1, true)",
      ae(
        EFunc("TEST", [
          ae(ELit(VInt(1)), meta(5, 1, 6)),
          ae(ELit(VBool(true)), meta(8, 1, 9))
        ]),
        meta(0, 1, 1)
      )
    );
  }

  public function testBinOp() {
    assertParseString("1+2",
      ae(
        EBinOp(
          "+",
          6,
          ae(ELit(VInt(1)), meta(0, 1, 1)),
          ae(ELit(VInt(2)), meta(2, 1, 3))
        ),
        meta(1, 1, 2)
      )
    );

    assertParseString("(1+2)",
      ae(
        EBinOp(
          "+",
          6,
          ae(ELit(VInt(1)), meta(1, 1, 2)),
          ae(ELit(VInt(2)), meta(3, 1, 4))
        ),
        meta(2, 1, 3)
      )
    );

    assertParseString(" 1  + 2  ",
      ae(
        EBinOp(
          "+",
          6,
          ae(ELit(VInt(1)), meta(1, 1, 2)),
          ae(ELit(VInt(2)), meta(6, 1, 7))
        ),
        meta(4, 1, 5)
      )
    );

    assertParseString("1 + 2 * 3",
      ae(
        EBinOp(
          "+",
          6,
          ae(ELit(VInt(1)), meta(0, 1, 1)),
          ae(
            EBinOp(
              "*",
              7,
              ae(ELit(VInt(2)), meta(4, 1, 5)),
              ae(ELit(VInt(3)), meta(8, 1, 9))
            ),
            meta(6, 1, 7)
          )
        ),
        meta(2, 1, 3)
      )
    );

    assertParseString("(1 + 2) * 3",
      ae(
        EBinOp(
          "*",
          7,
          ae(
            EBinOp(
              "+",
              6,
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
      )
    );

    assertParseString("(1 + (2 + (3 + 4)))",
      ae(
        EBinOp(
          "+",
          6,
          ae(ELit(VInt(1)), meta(1, 1, 2)),
          ae(
            EBinOp(
              "+",
              6,
              ae(ELit(VInt(2)), meta(6, 1, 7)),
              ae(
                EBinOp(
                  "+",
                  6,
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
      )
    );
  }

  public function testParseStringMap() : Void {
    assertParseStringMap([
      "a" => ae(ELit(VInt(0)), meta(0, 1, 1)),
      "b" => ae(
        EBinOp(
          "+",
          6,
          ae(ELit(VInt(1)), meta(0, 1, 1)),
          ae(EVar("a"), meta(4, 1, 5))
        ),
        meta(2, 1, 3)
      ),
      "c" => ae(EVar("d"), meta(0, 1, 1))
    ], [
      "a" => "0",
      "b" => "1 + a",
      "c" => "d"
    ]);
  }

  public function testParseStringMapError() : Void {
    var input = [
      "a" => "1.1.1", // bad
      "b" => "c",
      "c" => "" // bad
    ];
    switch ExprParser.parseStringMap(input, TestHelper.getTestParserOptions()) {
      case Left(errors) : Assert.same(2, errors.toArray().length);
      case Right(_) : Assert.fail("Should have failed to parse");
    };
  }

  public static function assertParseStringMap(expected : Map<String, SimpleAnnotatedExpr>, input : Map<String, String>, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parseStringMap(input, TestHelper.getTestParserOptions()) {
      case Left(errors) : Assert.fail('failed to parse map: ${errors}', pos);
      case Right(actual): Assert.same(expected, actual);
    };
  }
}
