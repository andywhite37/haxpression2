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

typedef UnOp = {
  operator : String
};

typedef ExprParserOptions<V, N, /*I, F, B,*/ A> = {
  variableNameRegexp: EReg,
  //convertVariable: String -> V,
  functionNameRegexp: EReg,
  //functions: Map<String, F>,
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
  //exprParen: Parser<Expr<V, A>>,
  expr: Parser<AnnotatedExpr<V, A>>
};

class ExprParser {

  public static function create<V, N, A>(options: ExprParserOptions<V, N, A>) : ExprParsers<V, A> {
    var valueParser = ValueParser.create(options).value;
    var meta = options.meta;
    var ae = AnnotatedExpr.new;

    // Pre-declare for recursive/lazy use
    var expr : Parser<AnnotatedExpr<V, A>>;

    var exprLit : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      valueParser.map(v -> ae(ELit(options.convertValue(v)), meta(index)))
    );

    var exprVar : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      options.variableNameRegexp.regexp().map(v -> ae(EVar(v), meta(index)))
    );

    var exprFunc : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      options.functionNameRegexp.regexp()
        .flatMap(functionName ->
          C.ows
            .skip(string("("))
            .skip(C.ows)
            .then(sepBy(expr, C.ows.then(string(",")).skip(C.ows)))
            .skip(string(")"))
            .map(args -> ae(EFunc(functionName, args), meta(index)))
        )
    );

    var exprParen : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      string("(")
        .skip(C.ows)
        .then(expr)
        .skip(C.ows)
        .skip(string(")"))
    );

    var baseTerm : Parser<AnnotatedExpr<V, A>> =
      C.ows
        .then(choice([exprParen, exprFunc, exprLit, exprVar]))
        .skip(C.ows);

    // Create binary operator parsers
    var binOps : Array<Parser<AnnotatedExprBinOp<V, A>>> =
      options.binOps
        .order(function(a : BinOp, b : BinOp) : Int {
          return b.precedence - a.precedence;
        })
        .map(function(binOp : BinOp) : Parser<AnnotatedExprBinOp<V, A>> {
          //trace(binOp.operator);
          return index().flatMap(index ->
            C.ows
              .then(regexp(binOp.operatorRegexp))
              .map(op -> (left, right) -> ae(EBinOp(op, left, right), meta(index)))
          );
        });

    // create the parser chain with highest precedence bin op parsers down to base terms
    expr = lazy(() ->
      binOps.reduce(function(term : Parser<AnnotatedExpr<V, A>>, binOp : Parser<AnnotatedExprBinOp<V, A>>) {
        return term.chainl1(binOp);
      }, baseTerm)
    );

    return {
      //exprParen: exprParen,
      expr: expr
    };
  }

  public static function parse<V, N, A>(input : String, options : ExprParserOptions<V, N, A>) : Either<ParseError<AnnotatedExpr<V, A>>, AnnotatedExpr<V, A>> {
    var parseResult : Result<AnnotatedExpr<V, A>> = create(options).expr.skip(eof()).apply(input);
    return if (parseResult.status) {
      Right(parseResult.value);
    } else {
      Left(ParseError.fromParseResult(input, parseResult));
    };
  }
}
