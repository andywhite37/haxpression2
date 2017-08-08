package haxpression2;

import TestHelper.assertExprGetVars;

class TestExpr {
  public function new() {}

  public function testGetVars() : Void {
    assertExprGetVars([], "1 + 2 + 3 / 4");
    assertExprGetVars(["a", "b"], "1 + a + 3 / b + NA");
    assertExprGetVars(["a", "c", "b"], "a + c + 3 / b + NA + b + c + b");
  }
}
