package haxpression2;

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
  convertValue: Value<N> -> V,
  binOps: Array<BinOp>,
  unOps: {
    pre: Array<UnOp>,
    post: Array<UnOp>
  },
  meta: Index -> A
};

typedef ExprParsers<V, A> = {
  expr: Parser<Expr<V, A>>
};

class ExprParser {

  public static function create<V, N, A>(options: ExprParserOptions<V, N, A>) : ExprParsers<V, A> {
    var valueParser = ValueParser.create(options).value;
    var meta = options.meta;

    var expr : Parser<Expr<V, A>>;

    var exprLit : Parser<Expr<V, A>> = index().flatMap(index ->
      valueParser.map(v -> ELit(options.convertValue(v), meta(index)))
    );

    var exprVar : Parser<Expr<V, A>> = index().flatMap(index ->
      options.variableNameRegexp.regexp().map(v -> EVar(v, meta(index)))
    );

    var exprParen : Parser<Expr<V, A>> = index().flatMap(index ->
      string("(")
        .skip(C.ows)
        .then(expr)
        .skip(C.ows)
        .skip(string(")"))
    );

    var addTerm : Parser<Expr<V, A>> =
      C.ows
        .then(choice([exprParen, exprLit, exprVar]))
        .skip(C.ows);

    var addOp : Parser<Expr<V, A> -> Expr<V, A> -> Expr<V, A>> = index().flatMap(index ->
       C.ows
        .then(regexp(~/\+/).map(op -> (l, r) -> EBinOp(op, l, r, meta(index))))
        .skip(C.ows)
    );

    expr = chainl1(addTerm, addOp);

    return {
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
