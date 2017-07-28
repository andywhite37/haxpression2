package haxpression2;

using thx.Strings;

import Parsihax.*;
using Parsihax;
import Parsihax.Parser;
//import parsihax.ParseResult;

class CoreParser {
  // Whitespace
  public static var ws(default, never) : Parser<String> = whitespace();
  public static var ows(default, never) : Parser<String> = optWhitespace();

  // Integers
  static var integerZero(default, never) : Parser<Int> = "0".string().map(Std.parseInt);
  static var integerNonZero(default, never) : Parser<Int> = ~/[1-9][0-9]*/.regexp().map(Std.parseInt);
  static var integerNonZeroNeg(default, never) : Parser<Int> = ~/\-[1-9][0-9]*/.regexp().map(Std.parseInt);
  public static var integer(default, never) : Parser<Int> = choice([integerZero, integerNonZero, integerNonZeroNeg]);
  //public static var integer(default, never) : Parser<Int> = choice([integerZero, integerNonZero]);

  // Floats
  static var unsignedFloatWithLeadingDigits(default, never) : Parser<Float> = ~/\d[\d,]*(?:\.\d+)(?:e-?\d+)?/.regexp().map(v -> Std.parseFloat(v.replace(",", "")));
  static var unsignedFloatWithoutLeadingDigits(default, never) : Parser<Float> = ~/\.\d+(?:e-?\d+)/.regexp().map(Std.parseFloat);
  static var unsignedFloat(default, never) : Parser<Float> = choice([unsignedFloatWithLeadingDigits, unsignedFloatWithoutLeadingDigits]);
  static var positiveFloat(default, never) : Parser<Float> = ~/\+?/.regexp().then(ows).then(unsignedFloat);
  static var negativeSignFloat(default, never) : Parser<Float> = "-".string().then(ows).then(unsignedFloat);
  static var negativeParenFloat(default, never) : Parser<Float> = "(".string().then(ows).then(unsignedFloat).skip(ows).skip(")".string());
  static var negativeFloat(default, never) : Parser<Float> = choice([negativeSignFloat, negativeParenFloat]).map(v -> -v);
  public static var float(default, never) : Parser<Float> = choice([negativeFloat, positiveFloat]);
  //public static var float(default, never) : Parser<Float> = unsignedFloat;

  // Bools
  static var boolTrue(default, never) : Parser<Bool> = ~/true/i.regexp().map(v -> true);
  static var boolFalse(default, never) : Parser<Bool> = ~/false/i.regexp().map(v -> false);
  public static var bool(default, never) : Parser<Bool> = choice([boolTrue, boolFalse]);

  // Strings
  static var stringDoubleQuote(default, never) : Parser<String> = ~/"[^"]*"/.regexp().map(str -> str.trimChars('"'));
  static var stringSingleQuote(default, never) : Parser<String> = ~/'[^']*'/.regexp().map(str -> str.trimChars("'"));
  public static var string(default, never) : Parser<String> = choice([stringDoubleQuote, stringSingleQuote]);
}
