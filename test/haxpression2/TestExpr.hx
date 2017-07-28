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

import haxpression2.TestHelper.eval;
import haxpression2.TestHelper.parse;
import haxpression2.TestHelper.roundTrip;
import haxpression2.TestHelper.traceExpr;

class TestExpr {
  public function new() {}

  public function testRoundTrip() {
    Assert.same("1 + 2 + 3", roundTrip("1 + 2 + 3"));
    Assert.same("1 + 2 + 3", roundTrip("1 + (2 + 3)"));
    Assert.same("1 + 2 + 3", roundTrip("(1 + (2) + 3)"));
    Assert.same("1 + 2 + 3", roundTrip("((1 + 2) + 3)"));
    Assert.same("1 * 2 + 3", roundTrip("1 * 2 + 3"));
    Assert.same("1 * (2 + 3)", roundTrip("(1 * (2 + 3))"));
    Assert.same("1 + 2 - 3 * 4 / 5", roundTrip("1+2-3*4/5"));
    Assert.same("1 / 2 * 3 - 4 + 5", roundTrip("1/2*3-4+5"));
    Assert.same("1 + 2 * 3 - 4", roundTrip("1 + 2 * 3 - 4"));
    Assert.same("1 * 2 + 3 * 4", roundTrip("1 * 2 + 3 * 4"));
    Assert.same("1 * 2 + 3 * 4", roundTrip("1 * 2 + 3 * 4"));
    Assert.same("(1 + 2) * (3 - 4)", roundTrip("( 1 + 2 ) * ( 3 - 4 )"));
    Assert.same("1 + x * myFunc(true, false, \"hi\") / sales", roundTrip("1+x*myFunc ( true, false,  'hi'  ) / sales "));
    Assert.same("1 + x * myFunc(1 * (2 + 3)) / sales", roundTrip("1+x*myFunc (1 * (2 + 3)) / sales "));
  }

  public function testEval() {
    Assert.same(Right(VInt(0)), eval("0"));
    Assert.same(Right(VInt(3)), eval("1+2"));
    Assert.same(Right(VNum(1 + 2 - 3 * 4 / 5)), eval("1 + 2 - 3 * 4 / 5"));
    Assert.same(Right(VNum(1 / 2 * 3 - 4 + 5)), eval("1 / 2 * 3 - 4 + 5"));
    Assert.same(Right(VInt(1 + 2 * 3 + 4)), eval("1 + 2 * 3 + 4"));
    Assert.same(Right(VInt(1 + 2 * (3 + 4))), eval("1 + 2 * (3 + 4)"));
    Assert.same(Right(VInt((1+2) * (3+4))), eval("(1 + 2) * (3 + 4)"));
    Assert.same(Right(VNum(101)), eval("(1 + x + y + z) / b"));

    Assert.same(Right(VInt(-2)), eval("1 + -3"));
    Assert.same(Right(VInt(4)), eval("1 - (-3)"));

    Assert.same(Right(VBool(true)), eval("true"));
    Assert.same(Right(VBool(false)), eval("false"));
    Assert.same(Right(VBool(false)), eval("~true"));
    Assert.same(Right(VBool(true)), eval("~false"));
    Assert.same(Right(VBool(true)), eval("true || true"));
    Assert.same(Right(VBool(true)), eval("true || false"));
    Assert.same(Right(VBool(true)), eval("false || true"));
    Assert.same(Right(VBool(false)), eval("false || false"));
    Assert.same(Right(VBool(true)), eval("true || ~true"));
    Assert.same(Right(VBool(true)), eval("true || ~false"));
    Assert.same(Right(VBool(false)), eval("false || ~true"));
    Assert.same(Right(VBool(true)), eval("false || ~false"));
    Assert.same(Right(VBool(true)), eval("~true || true"));
    Assert.same(Right(VBool(false)), eval("~true || false"));
    Assert.same(Right(VBool(true)), eval("~false || true"));
    Assert.same(Right(VBool(true)), eval("~false || false"));
    Assert.same(Right(VBool(false)), eval("~(true || true)"));
    Assert.same(Right(VBool(false)), eval("~(true || false)"));
    Assert.same(Right(VBool(false)), eval("~(false || true)"));
    Assert.same(Right(VBool(true)), eval("~(false || false)"));
  }
}
