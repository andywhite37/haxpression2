package haxpression2.render;

import TestHelper.assertFormat;

class TestExprRenderer {
  public function new() {}

  public function testFormat() {
    assertFormat("1 + 2 + 3", "1 + 2 + 3");
    assertFormat("1 + 2 + 3", "1 + (2 + 3)");
    assertFormat("1 + 2 + 3", "(1 + (2) + 3)");
    assertFormat("1 + 2 + 3", "((1 + 2) + 3)");
    assertFormat("1 * 2 + 3", "1 * 2 + 3");
    assertFormat("1 * (2 + 3)", "(1 * (2 + 3))");
    assertFormat("1 + 2 - 3 * 4 / 5", "1+2-3*4/5");
    assertFormat("1 / 2 * 3 - 4 + 5", "1/2*3-4+5");
    assertFormat("1 + 2 * 3 - 4", "1 + 2 * 3 - 4");
    assertFormat("1 * 2 + 3 * 4", "1 * 2 + 3 * 4");
    assertFormat("1 * 2 + 3 * 4", "1 * 2 + 3 * 4");
    assertFormat("(1 + 2) * (3 - 4)", "( 1 + 2 ) * ( 3 - 4 )");
    assertFormat("1 + x * myFunc(true, false, \"hi\") / sales", "1+x*myFunc ( true, false,  'hi'  ) / sales ");
    assertFormat("1 + x * myFunc(1 * (2 + 3)) / sales", "1+x*myFunc (1 * (2 + 3)) / sales ");
  }
}
