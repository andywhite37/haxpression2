package haxpression2;

import haxpression2.parse.ParseMeta.create as meta;

import TestHelper.assertAnnotatedExprVars;

class TestAnnotatedExpr {
  public function new() {}

  public function testGetVars() : Void {
    assertAnnotatedExprVars(new Map(), "1 + 2 + 3 / 4");

    assertAnnotatedExprVars([
      "a" => [meta(4, 1, 5)],
      "b" => [meta(12, 1, 13)]
    ], "1 + a + 3 / b + NA");

    assertAnnotatedExprVars([
      "a" => [
        meta(0, 1, 1),
        meta(40, 1, 41)
      ],
      "c" => [
        meta(4, 1, 5),
        meta(25, 1, 26),
        meta(47, 1, 48)
      ],
      "b" => [
        meta(12, 1, 13),
        meta(21, 1, 22),
        meta(29, 1, 30),
        meta(44, 1, 45),
      ]
    ], "a + c + 3 / b + NA + b + c + b * myFunc(a + b, c)");
  }
}
