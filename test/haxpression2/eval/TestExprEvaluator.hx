package haxpression2.eval;

import utest.Assert;

import haxpression2.AnnotatedExpr.create as ae;
import haxpression2.eval.AnnotatedExprEvaluator;
import haxpression2.eval.ExprEvaluator;
import haxpression2.parse.ParseMeta.create as meta;
import haxpression2.simple.SimpleExpr;

import TestHelper.assertEvalString;

class TestExprEvaluator {
  public function new() {}

  public function testEvalStringNumbers() {
    assertEvalString(VInt(0), "0");
    assertEvalString(VInt(3), "1+2");
    assertEvalString(VNum(1 + 2 - 3 * 4 / 5), "1 + 2 - 3 * 4 / 5");
    assertEvalString(VNum(1 / 2 * 3 - 4 + 5), "1 / 2 * 3 - 4 + 5");
    assertEvalString(VInt(1 + 2 * 3 + 4), "1 + 2 * 3 + 4");
    assertEvalString(VInt(1 + 2 * (3 + 4)), "1 + 2 * (3 + 4)");
    assertEvalString(VInt((1+2) * (3+4)), "(1 + 2) * (3 + 4)");
    assertEvalString(VNum(101.0), "(1 + x + y + z) / b");
    assertEvalString(VInt(-2), "1 + -3");
    assertEvalString(VInt(-2), "1 + -3");
    assertEvalString(VInt(4), "1 - (-3)");
    assertEvalString(VInt(4), "1 - -3");
    assertEvalString(VInt(2), "-1 - -3");
    assertEvalString(VInt(8), "10 - (-1 - -3)");
    assertEvalString(VInt(-2), "-(-1 - -3)");
  }

  public function testEvalStringBools() {
    assertEvalString(VBool(true), "true");
    assertEvalString(VBool(false), "false");
    assertEvalString(VBool(false), "~true");
    assertEvalString(VBool(true), "~false");
    assertEvalString(VBool(true), "true || true");
    assertEvalString(VBool(true), "true || false");
    assertEvalString(VBool(true), "false || true");
    assertEvalString(VBool(false), "false || false");
    assertEvalString(VBool(true), "true || ~true");
    assertEvalString(VBool(true), "true || ~false");
    assertEvalString(VBool(false), "false || ~true");
    assertEvalString(VBool(true), "false || ~false");
    assertEvalString(VBool(true), "~true || true");
    assertEvalString(VBool(false), "~true || false");
    assertEvalString(VBool(true), "~false || true");
    assertEvalString(VBool(true), "~false || false");
    assertEvalString(VBool(false), "~(true || true)");
    assertEvalString(VBool(false), "~(true || false)");
    assertEvalString(VBool(false), "~(false || true)");
    assertEvalString(VBool(true), "~(false || false)");
  }

  public function testEvalStringError() {
    switch SimpleAnnotatedExprEvaluator.evalString("d", TestHelper.getTestExprParserOptions(), TestHelper.getTestExprEvaluatorOptions()) {
      case EvalErrors(Single(exprError)) :
        Assert.same("no variable definition was given for variable: d", exprError.error.message);
        Assert.same(ae(EVar("d"), meta(0, 1, 1)), exprError.error.expr);
        Assert.same(ae(EVar("d"), meta(0, 1, 1)), exprError.expr);
      case bad : Assert.fail('unexpected evalString result: $bad');
    };

    switch SimpleAnnotatedExprEvaluator.evalString("a + d + e", TestHelper.getTestExprParserOptions(), TestHelper.getTestExprEvaluatorOptions()) {
      case EvalErrors(errors) if (errors.toArray().length == 2) :
        var errorArray = errors.toArray().reverse();

        Assert.same("no variable definition was given for variable: d", errorArray[0].error.message);
        Assert.same(ae(EVar("d"), meta(4, 1, 5)), errorArray[0].error.expr);
        Assert.same(ae(EVar("d"), meta(4, 1, 5)), errorArray[0].expr);

        Assert.same("no variable definition was given for variable: e", errorArray[1].error.message);
        Assert.same(ae(EVar("e"), meta(8, 1, 9)), errorArray[1].error.expr);
        Assert.same(ae(EVar("e"), meta(8, 1, 9)), errorArray[1].expr);

      case bad : Assert.fail('unexpected evalString result: $bad');
    };

    switch SimpleAnnotatedExprEvaluator.evalString("true + 1", TestHelper.getTestExprParserOptions(), TestHelper.getTestExprEvaluatorOptions()) {
      case EvalErrors(Single(exprError)) :
        Assert.same('cannot combine values of incompatible types: `VBool(true)` and `VInt(1)`', exprError.error.message);
        Assert.same(meta(5, 1, 6), exprError.error.expr.annotation);
      case bad : Assert.fail('unexpected evalString result: $bad');
    };

    switch SimpleAnnotatedExprEvaluator.evalString("true + 1 + 'hi'", TestHelper.getTestExprParserOptions(), TestHelper.getTestExprEvaluatorOptions()) {
      case EvalErrors(Single(exprError)) :
        Assert.same('cannot combine values of incompatible types: `VBool(true)` and `VInt(1)`', exprError.error.message);
        Assert.same(meta(5, 1, 6), exprError.error.expr.annotation);
      case bad : Assert.fail('unexpected evalString result: $bad');
    };

    switch SimpleAnnotatedExprEvaluator.evalString("true || false + 'hi'", TestHelper.getTestExprParserOptions(), TestHelper.getTestExprEvaluatorOptions()) {
      case EvalErrors(Single(exprError)) :
        Assert.same('cannot combine values of incompatible types: `VBool(false)` and `VStr(hi)`', exprError.error.message);
        Assert.same(meta(14, 1, 15), exprError.error.expr.annotation);
      case bad : Assert.fail('unexpected evalString result: $bad');
    };
  }
}
