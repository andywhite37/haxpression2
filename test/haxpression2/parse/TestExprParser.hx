package haxpression2.parse;

using Parsihax;

import haxpression2.AnnotatedExpr.create as ae;
using haxpression2.Value;
import haxpression2.parse.ParseMeta.create as meta;

import TestHelper.assertParseExpr;
import TestHelper.assertParseExprError;

class TestExprParser {
  public function new() {}

  public function testWhitespaceErrors() : Void {
    assertParseExprError("");
    assertParseExprError(" ");
    assertParseExprError("   ");
    assertParseExprError("\t");
    assertParseExprError("\t ");
    assertParseExprError("()");
    assertParseExprError("( )");
    assertParseExprError(",");
  }

  public function testLitNANM() : Void {
    assertParseExpr("NA", ae(ELit(VNA), meta(0, 1, 1)));
    assertParseExpr("na", ae(ELit(VNA), meta(0, 1, 1)));
    assertParseExpr("Na", ae(ELit(VNA), meta(0, 1, 1)));
    assertParseExpr("nA", ae(ELit(VNA), meta(0, 1, 1)));
    assertParseExpr("NM", ae(ELit(VNM), meta(0, 1, 1)));
    assertParseExpr("nm", ae(ELit(VNM), meta(0, 1, 1)));
    assertParseExpr("Nm", ae(ELit(VNM), meta(0, 1, 1)));
    assertParseExpr("nM", ae(ELit(VNM), meta(0, 1, 1)));
    assertParseExpr(
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
    assertParseExpr("0", ae(ELit(VInt(0)), meta(0, 1, 1)));
    assertParseExpr("1", ae(ELit(VInt(1)), meta(0, 1, 1)));
    assertParseExpr(" 1  ", ae(ELit(VInt(1)), meta(1, 1, 2)));
    assertParseExpr(" -1  ",
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
    assertParseExpr("0.0", ae(ELit(VNum(0.0)), meta(0, 1, 1)));
    assertParseExpr("1.0", ae(ELit(VNum(1.0)), meta(0, 1, 1)));
    assertParseExpr(" 1.1  ", ae(ELit(VNum(1.1)), meta(1, 1, 2)));
  }

  public function testLitBool() {
    assertParseExpr("true", ae(ELit(VBool(true)), meta(0, 1, 1)));
    assertParseExpr("false", ae(ELit(VBool(false)), meta(0, 1, 1)));
    assertParseExpr("   true ", ae(ELit(VBool(true)), meta(3, 1, 4)));
    assertParseExpr("  false ", ae(ELit(VBool(false)), meta(2, 1, 3)));
    assertParseExpr("True", ae(ELit(VBool(true)), meta(0, 1, 1)));
    assertParseExpr("False", ae(ELit(VBool(false)), meta(0, 1, 1)));
    assertParseExpr("TRUE", ae(ELit(VBool(true)), meta(0, 1, 1)));
    assertParseExpr("FALSE", ae(ELit(VBool(false)), meta(0, 1, 1)));
  }

  public function testVar() {
    assertParseExpr("a", ae(EVar("a"), meta(0, 1, 1)));
    assertParseExpr(" a", ae(EVar("a"), meta(1, 1, 2)));
    assertParseExpr(" a ", ae(EVar("a"), meta(1, 1, 2)));
    assertParseExpr("   a ", ae(EVar("a"), meta(3, 1, 4)));
    assertParseExpr("sales", ae(EVar("sales"), meta(0, 1, 1)));
    assertParseExpr(" sales", ae(EVar("sales"), meta(1, 1, 2)));
    assertParseExpr("   sales ", ae(EVar("sales"), meta(3, 1, 4)));
    assertParseExpr("asn!sales", ae(EVar("asn!sales"), meta(0, 1, 1)));
    assertParseExpr(" asn!sales", ae(EVar("asn!sales"), meta(1, 1, 2)));
    assertParseExpr("   asn!sales ", ae(EVar("asn!sales"), meta(3, 1, 4)));
  }

  public function testVarErrors() {
    assertParseExprError("x y");
    assertParseExprError("!asn");
    assertParseExprError("asn!");
    assertParseExprError("asn!!sales");
    assertParseExprError("asn!sales x");
  }

  public function testFunc() {
    assertParseExpr("TEST()",
      ae(
        EFunc("TEST", []),
        meta(0, 1, 1)
      )
    );

    assertParseExpr(" TEST (   ) ",
      ae(
        EFunc("TEST", []),
        meta(1, 1, 2)
      )
    );

    assertParseExpr("TEST(1, true)",
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
    assertParseExpr("1+2",
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

    assertParseExpr("(1+2)",
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

    assertParseExpr(" 1  + 2  ",
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

    assertParseExpr("1 + 2 * 3",
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

    assertParseExpr("(1 + 2) * 3",
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

    assertParseExpr("(1 + (2 + (3 + 4)))",
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
}
