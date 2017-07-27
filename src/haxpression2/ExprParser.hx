package haxpression2;

using thx.Arrays;
import thx.Either;
using thx.Strings;
import thx.Unit;

import Parsihax.*;
using Parsihax;
//import Parsihax.Parser;
//import Parsihax.ParseResult;

import haxpression2.CoreParser as C;
import haxpression2.Expr;
import haxpression2.Value;
import haxpression2.ValueParser as V;

typedef BinOp = {
  operator: String,
  precedence: Int
}

typedef UnOp = {
  operator : String
};

typedef ExprParserOptions<V, N, A> = {
  variableNameRegexp: EReg,
  functionNameRegexp: EReg,
  convertFloat: Float -> N,
  convertValue: Value<N> -> V,
  binOps: Array<BinOp>,
  unOps: {
    pre: Array<UnOp>,
    post: Array<UnOp>
  },
  meta: Index -> A
};

typedef ExprParsers<V, A> = {
  exprParen: Parser<Expr<V, A>>,
  expr: Parser<Expr<V, A>>
};

class ExprParser {

  public static function create<V, N, A>(options: ExprParserOptions<V, N, A>) : ExprParsers<V, A> {
    var valueParser = ValueParser.create(options).value;
    var meta = options.meta;

    // Pre-declare for recursive/lazy use
    var expr : Parser<Expr<V, A>>;

    var exprLit : Parser<Expr<V, A>> = index().flatMap(index ->
      valueParser.map(v -> ELit(options.convertValue(v), meta(index)))
    );

    var exprVar : Parser<Expr<V, A>> = index().flatMap(index ->
      options.variableNameRegexp.regexp().map(v -> EVar(v, meta(index)))
    );

    var exprFunc : Parser<Expr<V, A>> = index().flatMap(index ->
      options.functionNameRegexp.regexp()
        .flatMap(functionName ->
          C.ows
            .skip(string("("))
            .skip(C.ows)
            .then(sepBy(expr, C.ows.then(string(",")).skip(C.ows)))
            .skip(string(")"))
            .map(args -> EFunc(functionName, args, meta(index)))
        )
    );

    var exprParen : Parser<Expr<V, A>> = index().flatMap(index ->
      string("(")
        .skip(C.ows)
        .then(expr)
        .skip(C.ows)
        .skip(string(")"))
    );

    var baseTerm : Parser<Expr<V, A>> =
      C.ows
        .then(choice([exprParen, exprFunc, exprLit, exprVar]))
        .skip(C.ows);

    // var mulOp : Parser<Expr<V, A> -> Expr<V, A> -> Expr<V, A>> = index().flatMap(index ->
    //    C.ows
    //     .then(regexp(~/\*/).map(op -> (l, r) -> EBinOp(op, l, r, meta(index))))
    //     .skip(C.ows)
    // );

    // var addOp : Parser<Expr<V, A> -> Expr<V, A> -> Expr<V, A>> = index().flatMap(index ->
    //    C.ows
    //     .then(regexp(~/\+/).map(op -> (l, r) -> EBinOp(op, l, r, meta(index))))
    //     .skip(C.ows)
    // );

    // // in order of precedence (higher to lower)
    // var binOps : Array<Parser<Expr<V,A> -> Expr<V,A> -> Expr<V,A>>> = [mulOp, addOp];

    var binOps : Array<Parser<Expr<V,A> -> Expr<V,A> -> Expr<V, A>>> =
      options.binOps
        .order(function(a : BinOp, b : BinOp) : Int {
          return if (a.precedence == b.precedence) {
            // If precedence is equal, do the longer-named operators first
            b.operator.length - a.operator.length;
          } else {
            // Order by precedence (higher to lower)
            b.precedence - a.precedence;
          }
        })
        .map(function(binOp : BinOp) : Parser<Expr<V,A> -> Expr<V, A> -> Expr<V, A>> {
          //trace(binOp.operator);
          return index().flatMap(index ->
            C.ows
              .then(string(binOp.operator))
              .map(op -> (left, right) -> EBinOp(op, left, right, meta(index)))
          );
        });

    expr = lazy(() ->
      binOps.reduce(function(term : Parser<Expr<V, A>>, binOp : Parser<Expr<V, A> -> Expr<V, A> -> Expr<V, A>>) {
        return term.chainl1(binOp);
      }, baseTerm)
    );

    return {
      exprParen: exprParen,
      expr: expr
    };
  }

  public static function parse<V, N, A>(input : String, options : ExprParserOptions<V, N, A>) : Either<ParseError, Expr<V, A>> {
    var parseResult : Result<Expr<V, A>> = create(options).expr.skip(eof()).apply(input);
    return if (parseResult.status) {
      Right(parseResult.value);
    } else {
      Left(ParseError.fromParseResult(input, parseResult));
    };
  }
}
