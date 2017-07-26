package haxpression2;

using thx.Strings;

import parsihax.Parser.*;
using parsihax.Parser;
import parsihax.ParseObject;
//import parsihax.ParseResult;

class CoreParser {
  // Whitespace
  public static var ws(default, never) : ParseObject<String> = whitespace();
  public static var ows(default, never) : ParseObject<String> = optWhitespace();

  // Integers
  public static var integerZero(default, never) : ParseObject<Int> = "0".string().map(Std.parseInt);
  public static var integerNonZero(default, never) : ParseObject<Int> = ~/[1-9][0-9]*/.regexp().map(Std.parseInt);
  public static var integerNonZeroNeg(default, never) : ParseObject<Int> = ~/\-[1-9][0-9]*/.regexp().map(Std.parseInt);
  public static var integer(default, never) : ParseObject<Int> = integerZero | integerNonZero | integerNonZeroNeg;

  // Floats
  static var unsignedFloatWithLeadingDigits(default, never) : ParseObject<Float> = ~/\d[\d,]*(?:\.\d+)(?:e-?\d+)?/.regexp().map(v -> Std.parseFloat(v.replace(",", "")));
  static var unsignedFloatWithoutLeadingDigits(default, never) : ParseObject<Float> = ~/\.\d+(?:e-?\d+)/.regexp().map(Std.parseFloat);
  static var unsignedFloat(default, never) : ParseObject<Float> = unsignedFloatWithLeadingDigits | unsignedFloatWithoutLeadingDigits;
  static var positiveFloat(default, never) : ParseObject<Float> = ~/\+?/.regexp() + ows + unsignedFloat;
  static var negativeSignFloat(default, never) : ParseObject<Float> = "-".string() + ows + unsignedFloat;
  static var negativeParenFloat(default, never) : ParseObject<Float> = "(".string() + ows + unsignedFloat.skip(ows + ")".string());
  static var negativeFloat(default, never) : ParseObject<Float> = (negativeSignFloat | negativeParenFloat).map(v -> -v);
  public static var float(default, never) : ParseObject<Float> = negativeFloat | positiveFloat;

  // Bools
  static var boolTrue(default, never) : ParseObject<Bool> = ~/true/i.regexp().map(v -> true);
  static var boolFalse(default, never) : ParseObject<Bool> = ~/false/i.regexp().map(v -> false);
  public static var bool(default, never) : ParseObject<Bool> = boolTrue | boolFalse;

  // Strings
  static var stringDoubleQuote(default, never) : ParseObject<String> = ~/"[^"]*"/.regexp().map(str -> str.trimChars('"'));
  static var stringSingleQuote(default, never) : ParseObject<String> = ~/'[^']*'/.regexp().map(str -> str.trimChars("'"));
  public static var string(default, never) : ParseObject<String> = stringDoubleQuote | stringSingleQuote;
}
