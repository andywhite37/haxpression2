package haxpression2;

using Parsihax;

using haxpression2.Expr;
import haxpression2.Expr.AnnotatedExpr.create as ae;
import haxpression2.ParseMeta;
import haxpression2.ParseMeta.create as meta;
using haxpression2.Value;

import TestHelper.assertParse;
import TestHelper.assertParseError;

class TestExprParser {
  var exprParser : Parser<AnnotatedExpr<Value<Float>, ParseMeta>>;

  public function new() {}

  public function setup() {
    exprParser = TestHelper.getTestExprParser();
  }

  public function testWhitespaceErrors() {
    assertParseError("");
    assertParseError(" ");
    assertParseError("   ");
    assertParseError("\t");
    assertParseError("\t ");
    assertParseError("()");
    assertParseError("( )");
    assertParseError(",");
  }

  public function testLitNum() {
    assertParse("0.0", ae(ELit(VNum(0.0)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse("1.0", ae(ELit(VNum(1.0)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse(" 1.1  ", ae(ELit(VNum(1.1)), new ParseMeta({ offset: 1, line: 1, column: 2 })));
  }

  public function testLitInt() {
    assertParse("0", ae(ELit(VInt(0)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse("1", ae(ELit(VInt(1)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse(" 1  ", ae(ELit(VInt(1)), new ParseMeta({ offset: 1, line: 1, column: 2 })));
    assertParse(" -1  ",
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

  public function testLitBool() {
    assertParse("true", ae(ELit(VBool(true)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse("false", ae(ELit(VBool(false)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse("   true ", ae(ELit(VBool(true)), new ParseMeta({ offset: 3, line: 1, column: 4 })));
    assertParse("  false ", ae(ELit(VBool(false)), new ParseMeta({ offset: 2, line: 1, column: 3 })));
    assertParse("True", ae(ELit(VBool(true)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse("False", ae(ELit(VBool(false)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse("TRUE", ae(ELit(VBool(true)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
    assertParse("FALSE", ae(ELit(VBool(false)), new ParseMeta({ offset: 0, line: 1, column: 1 })));
  }

  public function testVar() {
    assertParse("a", ae(EVar("a"), meta(0, 1, 1)));
    assertParse(" a", ae(EVar("a"), meta(1, 1, 2)));
    assertParse(" a ", ae(EVar("a"), meta(1, 1, 2)));
    assertParse("   a ", ae(EVar("a"), meta(3, 1, 4)));
    assertParse("sales", ae(EVar("sales"), meta(0, 1, 1)));
    assertParse(" sales", ae(EVar("sales"), meta(1, 1, 2)));
    assertParse("   sales ", ae(EVar("sales"), meta(3, 1, 4)));
    assertParse("asn!sales", ae(EVar("asn!sales"), meta(0, 1, 1)));
    assertParse(" asn!sales", ae(EVar("asn!sales"), meta(1, 1, 2)));
    assertParse("   asn!sales ", ae(EVar("asn!sales"), meta(3, 1, 4)));
  }

  public function testVarErrors() {
    assertParseError("x y");
    assertParseError("!asn");
    assertParseError("asn!");
    assertParseError("asn!!sales");
    assertParseError("asn!sales x");
  }

  public function testFunc() {
    assertParse("TEST()",
      ae(
        EFunc("TEST", []),
        meta(0, 1, 1)
      )
    );

    assertParse(" TEST (   ) ",
      ae(
        EFunc("TEST", []),
        meta(1, 1, 2)
      )
    );

    assertParse("TEST(1, true)",
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
    assertParse("1+2",
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

    assertParse("(1+2)",
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

    assertParse(" 1  + 2  ",
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

    assertParse("1 + 2 * 3",
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

    assertParse("(1 + 2) * 3",
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

    assertParse("(1 + (2 + (3 + 4)))",
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
