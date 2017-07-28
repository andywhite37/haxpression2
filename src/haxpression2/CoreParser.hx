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

  // Decimals (parsed in string format, so the Expr type can parse into the appropriate Float/Decimal type)
  static var unsignedDecimalWithLeadingDigits(default, never) : Parser<String> = ~/\d[\d,]*(?:\.\d+)(?:e-?\d+)?/.regexp().map(v -> v.replace(",", ""));
  static var unsignedDecimalWithoutLeadingDigits(default, never) : Parser<String> = ~/\.\d+(?:e-?\d+)/.regexp();
  static var unsignedDecimal(default, never) : Parser<String> = choice([unsignedDecimalWithLeadingDigits, unsignedDecimalWithoutLeadingDigits]);
  static var positiveDecimal(default, never) : Parser<String> = ~/\+?/.regexp().then(ows).then(unsignedDecimal);
  static var negativeSignDecimal(default, never) : Parser<String> = "-".string().then(ows).then(unsignedDecimal);
  /*
  static var negativeParenDecimal(default, never) : Parser<String> =
    "(".string()
      .then(ows)
      .then(unsignedDecimal)
      .skip(ows)
      .skip(")".string())
      .map(str -> '-${str.trim().trimCharsLeft("(").trimCharsRight(")")}');
      */
  static var negativeDecimal(default, never) : Parser<String> = choice([negativeSignDecimal/*, negativeParenDecimal*/]);
  public static var decimalString(default, never) : Parser<String> = choice([negativeDecimal, positiveDecimal]);

  // Bools
  static var boolTrue(default, never) : Parser<Bool> = ~/true/i.regexp().map(v -> true);
  static var boolFalse(default, never) : Parser<Bool> = ~/false/i.regexp().map(v -> false);
  public static var bool(default, never) : Parser<Bool> = choice([boolTrue, boolFalse]);

  // Strings
  static var stringDoubleQuote(default, never) : Parser<String> = ~/"[^"]*"/.regexp().map(str -> str.trimChars('"'));
  static var stringSingleQuote(default, never) : Parser<String> = ~/'[^']*'/.regexp().map(str -> str.trimChars("'"));
  public static var string(default, never) : Parser<String> = choice([stringDoubleQuote, stringSingleQuote]);
}
