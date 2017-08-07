package haxpression2.eval;

import utest.Assert;

import haxpression2.Expr.AnnotatedExpr.create as ae;
import haxpression2.eval.EvalError;
import haxpression2.parse.ParseMeta.create as meta;
import haxpression2.simple.FloatExpr;

import TestHelper.assertParseEval;
import TestHelper.assertRoundTrip;

class TestExprEvaluator {
  public function new() {}

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

  public function testParseEvalError() {
    switch FloatExprs.parseEval("d", TestHelper.getTestParserOptions(), TestHelper.getTestEvalOptions()) {
      case EvalErrors(Single(exprError)) :
        Assert.same("no variable definition was given for variable: d", exprError.error.message);
        Assert.same(ae(EVar("d"), meta(0, 1, 1)), exprError.error.expr);
        Assert.same(ae(EVar("d"), meta(0, 1, 1)), exprError.expr);
      case bad : Assert.fail('unexpected parseEval result: $bad');
    };

    switch FloatExprs.parseEval("a + d + e", TestHelper.getTestParserOptions(), TestHelper.getTestEvalOptions()) {
      case EvalErrors(errors) if (errors.toArray().length == 2) :
        var errorArray = errors.toArray().reverse();

        Assert.same("no variable definition was given for variable: d", errorArray[0].error.message);
        Assert.same(ae(EVar("d"), meta(4, 1, 5)), errorArray[0].error.expr);
        Assert.same(ae(EVar("d"), meta(4, 1, 5)), errorArray[0].expr);

        Assert.same("no variable definition was given for variable: e", errorArray[1].error.message);
        Assert.same(ae(EVar("e"), meta(8, 1, 9)), errorArray[1].error.expr);
        Assert.same(ae(EVar("e"), meta(8, 1, 9)), errorArray[1].expr);

      case bad : Assert.fail('unexpected parseEval result: $bad');
    };
  }
}
