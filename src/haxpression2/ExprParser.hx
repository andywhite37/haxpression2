package haxpression2;

import thx.Either;
using thx.Strings;
import thx.Unit;

import parsihax.Parser.*;
using parsihax.Parser;
import parsihax.ParseObject;
import parsihax.ParseResult;

import haxpression2.CoreParser as C;
import haxpression2.Expr;
import haxpression2.Value;
import haxpression2.ValueParser as V;

enum Assoc {
  AssocLeft;
  AssocRight;
}

typedef BinOp = {
  op: String,
  precedence: Int,
  assoc: Assoc
}

typedef UnOp = {
  op : String
};

typedef ExprParserOptions<V, N, A> = {
  variableNameRegexp: EReg,
  functionNameRegexp: EReg,
  convertFloat: Float -> N,
  convertValue: Value<N, A> -> V,
  binOps: Array<BinOp>,
  unOps: {
    pre: Array<UnOp>,
    post: Array<UnOp>
  },
  meta: Int -> A
};

class ExprParser {
  public static function exprLit<V, N, A>(options: ExprParserOptions<V, N, A>) : ParseObject<Expr<V, A>> {
    return index().flatMap(index ->
      V.value(options).map(v -> ELit(options.convertValue(v), options.meta(index)))
    );
  }

  public static function exprVar<V, N, A>(options: ExprParserOptions<V, N, A>) : ParseObject<Expr<V, A>> {
    return index().flatMap(index ->
      options.variableNameRegexp.regexp().map(name -> EVar(name, options.meta(index)))
    );
  }

  public static function binOp<V, N, A>(options : ExprParserOptions<V, N, A>) : ParseObject<String> {
    return "+".string();
  }

  public static function exprBinOp<V, N, A>(options: ExprParserOptions<V, N, A>) : ParseObject<Expr<V, A>> {
    return index().flatMap(index ->
      C.ows
        .then(expr(options))
        .sepBy(binOp(options))
        .skip(C.ows)
        .flatMap(function(exprs : Array<Expr<V, A>>) : ParseObject<Expr<V, A>> {
          return if (exprs.length <= 1) {
            fail('expected to find at least two expressions for bin op');
          } else {
            succeed(EBinOp("+", exprs[0], exprs[1], options.meta(index)));
          }
        })
    );
    /*
    return index().flatMap(function(index : Int) {
      trace('exprBinOp $index');
      return ows()
        .then(expr(options))
        .skip(ows())
        .flatMap(function(left : Expr<N, ParseMeta>) {
          return binOp(options)
            .skip(ows())
            .flatMap(function(operator : String) {
               return expr(options)
                .skip(ows())
                .map(function(right : Expr<N, ParseMeta>) : Expr<N, ParseMeta> {
                  return EBinOp(operator, left, right, new ParseMeta(index));
                });
            });
        });
    });
    */
  }

  public static function exprUnOpPre<V, A>() : ParseObject<Expr<V, A>> {
    throw new thx.error.NotImplemented();
  }

  public static function exprUnOpPost<V, A>() : ParseObject<Expr<V, A>> {
    throw new thx.error.NotImplemented();
  }

  public static function exprFunc<V, A>() : ParseObject<Expr<V, A>> {
    throw new thx.error.NotImplemented();
  }

  public static function exprCond<V, A>() : ParseObject<Expr<V, A>> {
    throw new thx.error.NotImplemented();
  }

  public static function expr<V, N, A>(options: ExprParserOptions<V, N, A>) : ParseObject<Expr<V, A>> {
    return C.ows
      .then(
        alt([
          //exprCond(),
          //exprBinOp(options),
          //exprUnOpPost(),
          //exprUnOpPre(),
          //exprFunc(),
          exprVar(options),
          exprLit(options)
        ])
      )
      .skip(C.ows);
  }

  public static function parse<V, N, A>(input : String, options : ExprParserOptions<V, N, A>) : Either<ParseError, Expr<V, A>> {
    var parseResult : ParseResult<Expr<V, A>> = expr(options).skip(eof()).apply(input);
    return if (parseResult.status) {
      Right(parseResult.value);
    } else {
      Left(ParseError.fromParseResult(input, parseResult));
    };
  }
}
