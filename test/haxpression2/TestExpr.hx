package haxpression2;

import TestHelper.assertParseEval;
import TestHelper.assertRoundTrip;

class TestExpr {
  public function new() {}

  public function testRoundTrip() {
    assertRoundTrip("1 + 2 + 3", "1 + 2 + 3");
    assertRoundTrip("1 + 2 + 3", "1 + (2 + 3)");
    assertRoundTrip("1 + 2 + 3", "(1 + (2) + 3)");
    assertRoundTrip("1 + 2 + 3", "((1 + 2) + 3)");
    assertRoundTrip("1 * 2 + 3", "1 * 2 + 3");
    assertRoundTrip("1 * (2 + 3)", "(1 * (2 + 3))");
    assertRoundTrip("1 + 2 - 3 * 4 / 5", "1+2-3*4/5");
    assertRoundTrip("1 / 2 * 3 - 4 + 5", "1/2*3-4+5");
    assertRoundTrip("1 + 2 * 3 - 4", "1 + 2 * 3 - 4");
    assertRoundTrip("1 * 2 + 3 * 4", "1 * 2 + 3 * 4");
    assertRoundTrip("1 * 2 + 3 * 4", "1 * 2 + 3 * 4");
    assertRoundTrip("(1 + 2) * (3 - 4)", "( 1 + 2 ) * ( 3 - 4 )");
    assertRoundTrip("1 + x * myFunc(true, false, \"hi\") / sales", "1+x*myFunc ( true, false,  'hi'  ) / sales ");
    assertRoundTrip("1 + x * myFunc(1 * (2 + 3)) / sales", "1+x*myFunc (1 * (2 + 3)) / sales ");
  }

  public function testParseEvalNumbers() {
    assertParseEval(VInt(0), "0");
    assertParseEval(VInt(3), "1+2");
    assertParseEval(VNum(1 + 2 - 3 * 4 / 5), "1 + 2 - 3 * 4 / 5");
    assertParseEval(VNum(1 / 2 * 3 - 4 + 5), "1 / 2 * 3 - 4 + 5");
    assertParseEval(VInt(1 + 2 * 3 + 4), "1 + 2 * 3 + 4");
    assertParseEval(VInt(1 + 2 * (3 + 4)), "1 + 2 * (3 + 4)");
    assertParseEval(VInt((1+2) * (3+4)), "(1 + 2) * (3 + 4)");
    assertParseEval(VNum(101.0), "(1 + x + y + z) / b");
    assertParseEval(VInt(-2), "1 + -3");
    assertParseEval(VInt(-2), "1 + -3");
    assertParseEval(VInt(4), "1 - (-3)");
    assertParseEval(VInt(4), "1 - -3");
    assertParseEval(VInt(2), "-1 - -3");
    assertParseEval(VInt(8), "10 - (-1 - -3)");
    assertParseEval(VInt(-2), "-(-1 - -3)");
  }

  public function testParseEvalBools() {
    assertParseEval(VBool(true), "true");
    assertParseEval(VBool(false), "false");
    assertParseEval(VBool(false), "~true");
    assertParseEval(VBool(true), "~false");
    assertParseEval(VBool(true), "true || true");
    assertParseEval(VBool(true), "true || false");
    assertParseEval(VBool(true), "false || true");
    assertParseEval(VBool(false), "false || false");
    assertParseEval(VBool(true), "true || ~true");
    assertParseEval(VBool(true), "true || ~false");
    assertParseEval(VBool(false), "false || ~true");
    assertParseEval(VBool(true), "false || ~false");
    assertParseEval(VBool(true), "~true || true");
    assertParseEval(VBool(false), "~true || false");
    assertParseEval(VBool(true), "~false || true");
    assertParseEval(VBool(true), "~false || false");
    assertParseEval(VBool(false), "~(true || true)");
    assertParseEval(VBool(false), "~(true || false)");
    assertParseEval(VBool(false), "~(false || true)");
    assertParseEval(VBool(true), "~(false || false)");
  }
}
