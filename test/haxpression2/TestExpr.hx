package haxpression2;

import utest.Assert;

import TestHelper.assertExprVars;
import TestHelper.assertAnnotatedExprVars;

class TestExpr {
  public function new() {}

  public function testGetVars() : Void {
    assertExprVars([], "1 + 2 + 3 / 4");
    assertExprVars(["a", "b"], "1 + a + 3 / b + NA");
    assertExprVars(["a", "c", "b"], "a + c + 3 / b + NA + b + c + b");
  }
}
