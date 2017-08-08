package haxpression2.render;

import TestHelper.assertFormatString;

class TestExprRenderer {
  public function new() {}

  public function testFormatString() {
    assertFormatString("1 + 2 + 3", "1 + 2 + 3");
    assertFormatString("1 + 2 + 3", "1 + (2 + 3)");
    assertFormatString("1 + 2 + 3", "(1 + (2) + 3)");
    assertFormatString("1 + 2 + 3", "((1 + 2) + 3)");
    assertFormatString("1 * 2 + 3", "1 * 2 + 3");
    assertFormatString("1 * (2 + 3)", "(1 * (2 + 3))");
    assertFormatString("1 + 2 - 3 * 4 / 5", "1+2-3*4/5");
    assertFormatString("1 / 2 * 3 - 4 + 5", "1/2*3-4+5");
    assertFormatString("1 + 2 * 3 - 4", "1 + 2 * 3 - 4");
    assertFormatString("1 * 2 + 3 * 4", "1 * 2 + 3 * 4");
    assertFormatString("1 * 2 + 3 * 4", "1 * 2 + 3 * 4");
    assertFormatString("(1 + 2) * (3 - 4)", "( 1 + 2 ) * ( 3 - 4 )");
    assertFormatString("1 + x * myFunc(true, false, \"hi\") / sales", "1+x*myFunc ( true, false,  'hi'  ) / sales ");
    assertFormatString("1 + x * myFunc(1 * (2 + 3)) / sales", "1+x*myFunc (1 * (2 + 3)) / sales ");
  }
}
