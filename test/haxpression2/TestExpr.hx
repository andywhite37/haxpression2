package haxpression2;

using thx.Arrays;
import thx.Either;
using thx.Eithers;
import thx.Functions.identity;
import thx.Nel;
using thx.Validation;
import thx.Validation.*;

import utest.Assert;

using haxpression2.Expr;
using haxpression2.Value;

import haxpression2.TestHelper.assertEval;
import haxpression2.TestHelper.assertRoundTrip;
import haxpression2.TestHelper.traceExpr;

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

  public function testEvalNumbers() {
    assertEval(VInt(0), "0");
    assertEval(VInt(3), "1+2");
    assertEval(VNum(1 + 2 - 3 * 4 / 5), "1 + 2 - 3 * 4 / 5");
    assertEval(VNum(1 / 2 * 3 - 4 + 5), "1 / 2 * 3 - 4 + 5");
    assertEval(VInt(1 + 2 * 3 + 4), "1 + 2 * 3 + 4");
    assertEval(VInt(1 + 2 * (3 + 4)), "1 + 2 * (3 + 4)");
    assertEval(VInt((1+2) * (3+4)), "(1 + 2) * (3 + 4)");
    assertEval(VNum(101.0), "(1 + x + y + z) / b");
    assertEval(VInt(-2), "1 + -3");
    assertEval(VInt(-2), "1 + -3");
    assertEval(VInt(4), "1 - (-3)");
    assertEval(VInt(4), "1 - -3");
    assertEval(VInt(2), "-1 - -3");
    assertEval(VInt(8), "10 - (-1 - -3)");
    assertEval(VInt(-2), "-(-1 - -3)");
  }

  public function testEvalBools() {
    assertEval(VBool(true), "true");
    assertEval(VBool(false), "false");
    assertEval(VBool(false), "~true");
    assertEval(VBool(true), "~false");
    assertEval(VBool(true), "true || true");
    assertEval(VBool(true), "true || false");
    assertEval(VBool(true), "false || true");
    assertEval(VBool(false), "false || false");
    assertEval(VBool(true), "true || ~true");
    assertEval(VBool(true), "true || ~false");
    assertEval(VBool(false), "false || ~true");
    assertEval(VBool(true), "false || ~false");
    assertEval(VBool(true), "~true || true");
    assertEval(VBool(false), "~true || false");
    assertEval(VBool(true), "~false || true");
    assertEval(VBool(true), "~false || false");
    assertEval(VBool(false), "~(true || true)");
    assertEval(VBool(false), "~(true || false)");
    assertEval(VBool(false), "~(false || true)");
    assertEval(VBool(true), "~(false || false)");
  }
}
