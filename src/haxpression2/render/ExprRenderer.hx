package haxpression2.render;

using thx.Arrays;
import thx.Either;
using thx.Eithers;

import haxpression2.Expr;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;

typedef ExprFormatStringResult<V, A> = Either<ParseError<AnnotatedExpr<V, A>>, String> ;

class ExprRenderer {
  public static function renderString<V, A>(expr : Expr<V, A>, valueToString : V -> String) : String {
    return tokenize(expr, getStringTokenizeOptions(valueToString)).join("");
  }

  public static function formatString<V, D, A>(input : String, parserOptions : ExprParserOptions<V, D, A>, valueToString : V -> String) : ExprFormatStringResult<V, A> {
    return ExprParser.parseString(input, parserOptions).map(ae -> renderString(ae.expr, valueToString));
  }

  public static function tokenize<Token, V, A>(expr : Expr<V, A>, options : TokenizeOptions<Token, V>) : Array<Token> {
    function accTokenize(acc : Array<Token>, expr : Expr<V, A>, options: TokenizeOptions<Token, V>) : Array<Token> {
      return switch expr {
        case ELit(value) : acc.concat([options.lit(value)]);

        case EVar(name) : acc.concat([options.varName(name)]);

        case EFunc(name, argExprs) :
          var argTokens : Array<Token> = argExprs
            .map(argExpr -> tokenize(argExpr.expr, options)) // tokenize the args into separate token arrays
            .intersperse([options.funcComma]) // separate the arg token arrays with commas
            .flatten(); // flatten the final list of tokens

          acc
            .concat([options.funcName(name)])
            .concat([options.funcLeftParen])
            .concat(argTokens)
            .concat([options.funcRightParen]);

        case EUnOpPre(operator, precedence, operandExpr) :
          var operandTokens : Array<Token> = tokenize(operandExpr.expr, options);
          acc
            .concat([options.unOpPre(operator)])
            .concat(operandTokens);

        case EBinOp(operator, precedence, leftExpr, rightExpr) :
          var leftTokens = tokenize(leftExpr.expr, options);
          var leftTokensSafe = switch leftExpr.expr {
            case EBinOp(_, lprecedence, _, _) if (lprecedence < precedence) :
              // if a left-side bin op has lower precendence, parenthesize it
              [options.leftParen].concat(leftTokens).concat([options.rightParen]);
            case _ :
              leftTokens;
          };
          var rightTokens = tokenize(rightExpr.expr, options);
          var rightTokensSafe = switch rightExpr.expr {
            case EBinOp(_, rprecedence, _, _) if (rprecedence < precedence) :
              // if a right-side bin op has lower precendence, parenthesize it
              [options.leftParen].concat(rightTokens).concat([options.rightParen]);
            case _ :
              rightTokens;
          };
          acc
            .concat(leftTokensSafe)
            .concat([options.space])
            .concat([options.binOp(operator)])
            .concat([options.space])
            .concat(rightTokensSafe);
      };
    }
    return accTokenize([], expr, options);
  }

  public static function getStringTokenizeOptions<V>(valueToString : V -> String) : TokenizeOptions<String, V> {
    return {
      space: " ",
      lit: valueToString,
      varName: name -> name,
      funcName: name -> name,
      funcLeftParen: "(",
      funcRightParen: ")",
      funcComma: ", ",
      leftParen: "(",
      rightParen: ")",
      binOp: op -> op,
      unOpPre: op -> op
    };
  }
}

typedef TokenizeOptions<Token, V> = {
  space: Token,
  leftParen: Token,
  rightParen: Token,
  lit: V -> Token,
  varName: String -> Token,
  funcName: String -> Token,
  funcLeftParen: Token,
  funcRightParen: Token,
  funcComma: Token,
  binOp: String -> Token,
  unOpPre: String -> Token
};
