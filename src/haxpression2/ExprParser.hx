package haxpression2;

using thx.Arrays;
import thx.Either;

import Parsihax.*;
using Parsihax;

import haxpression2.CoreParser.ows;
import haxpression2.Expr;
import haxpression2.Value;

typedef ExprParserOptions<V, D, A> = {
  variableNameRegexp: EReg,
  functionNameRegexp: EReg,
  parseDecimal: String -> D,
  convertValue: Value<D> -> V,
  binOps: Array<BinOp>,
  unOps: {
    pre: Array<UnOp>,
    post: Array<UnOp>
  },
  annotate: Index -> A
};

typedef ExprParsers<V, A> = {
  expr: Parser<AnnotatedExpr<V, A>>,
  // Expose internal parsers for convenience
  _internal: {
    exprLit: Parser<AnnotatedExpr<V, A>>,
    exprVar: Parser<AnnotatedExpr<V, A>>,
    exprFunc: Parser<AnnotatedExpr<V, A>>,
    exprParen: Parser<AnnotatedExpr<V, A>>,
  }
};

class ExprParser {
  /**
   *  Creates an instance of an expression parser
   *
   *  @param options -
   *  @return ExprParsers<V, A>
   */
  public static function create<V, N, A>(options: ExprParserOptions<V, N, A>) : ExprParsers<V, A> {
    var valueParser = ValueParser.create(options).value;
    var meta = options.annotate;
    var ae = AnnotatedExpr.new;

    // Pre-declare main parser for recursive/lazy use
    var expr : Parser<AnnotatedExpr<V, A>>;

    // Literal value parser
    var exprLit : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      valueParser.map(v -> ae(ELit(options.convertValue(v)), meta(index)))
    );

    // Variable parser
    var exprVar : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      options.variableNameRegexp.regexp().map(v -> ae(EVar(v), meta(index)))
    );

    // Function parser
    var exprFunc : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      options.functionNameRegexp.regexp()
        .flatMap(functionName ->
          ows
            .skip(string("("))
            .skip(ows)
            .then(sepBy(expr, ows.then(string(",")).skip(ows)))
            .skip(string(")"))
            .map(args -> ae(EFunc(functionName, args), meta(index)))
        )
    );

    // Parenthesized expression parser
    var exprParen : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      string("(")
        .skip(ows)
        .then(expr)
        .skip(ows)
        .skip(string(")"))
    );

    // Base case expression parser
    var exprBaseTerm : Parser<AnnotatedExpr<V, A>> =
      ows
        .then(choice([exprParen, exprFunc, exprLit, exprVar]))
        .skip(ows);

    // Prefix unary operator parsers
    var exprUnOpPres : Array<Parser<AnnotatedExpr<V, A>>> =
      options.unOps.pre
        .order((a, b) -> b.precedence - a.precedence)
        .map(function(upOp : UnOp) : Parser<AnnotatedExpr<V, A>> {
          return ows.then(
            index().flatMap(index ->
              upOp.operatorRegexp.regexp()
                .flatMap(function(operatorString: String) {
                  return ows
                    .then(exprBaseTerm)
                    .map(ae -> new AnnotatedExpr(EUnOpPre(operatorString, ae), meta(index)));
                })
            )
          );
        });

    // Binary operator parsers
    var exprBinOps : Array<Parser<AnnotatedExprBinOp<V, A>>> =
      options.binOps
        .order((a, b) -> b.precedence - a.precedence) // precedence descending
        .map(function(binOp : BinOp) : Parser<AnnotatedExprBinOp<V, A>> {
          return index().flatMap(index ->
            ows
              .then(regexp(binOp.operatorRegexp))
              .map(operatorString -> (left, right) -> ae(EBinOp(operatorString, binOp.precedence, left, right), meta(index)))
          );
        });

    // Prefix unary + base parsers
    var exprUnOpPre = choice(exprUnOpPres).or(exprBaseTerm);

    // Binary operator parser
    var exprBinOp =
      exprBinOps.reduce(function(term : Parser<AnnotatedExpr<V, A>>, binOp : Parser<AnnotatedExprBinOp<V, A>>) {
        return term.chainl1(binOp);
      }, exprUnOpPre);

    // Main parser
    expr = lazy(() ->
      exprBinOp
    );

    return {
      expr: expr,
      _internal: {
        exprLit: exprLit,
        exprVar: exprVar,
        exprFunc: exprFunc,
        exprParen: exprParen,
      }
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
