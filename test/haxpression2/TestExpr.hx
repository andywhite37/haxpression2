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

import haxpression2.TestHelper.roundTrip;
import haxpression2.TestHelper.eval;

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
  }
}
