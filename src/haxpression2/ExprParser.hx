package haxpression2;

using thx.Arrays;
import thx.Either;

import Parsihax.*;
using Parsihax;

import haxpression2.CoreParser.ows;
import haxpression2.Expr;
import haxpression2.Value;

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

    // Parser for expression literal (value)
    var exprLit : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      valueParser.map(v -> ae(ELit(options.convertValue(v)), meta(index)))
    );

    // Parser for expression variable
    var exprVar : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      options.variableNameRegexp.regexp().map(v -> ae(EVar(v), meta(index)))
    );

    // Parser for expression function
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

    // Parser for parenthesized expressions
    var exprParen : Parser<AnnotatedExpr<V, A>> = index().flatMap(index ->
      string("(")
        .skip(ows)
        .then(expr)
        .skip(ows)
        .skip(string(")"))
    );

    // Base case for parsing expression
    var exprBaseTerm : Parser<AnnotatedExpr<V, A>> =
      ows
        .then(choice([exprParen, exprFunc, exprLit, exprVar]))
        .skip(ows);

    // Create binary operator parsers (these parse the operator and the right-side expression)
    var exprBinOps : Array<Parser<AnnotatedExprBinOp<V, A>>> =
      options.binOps
        // Order by operator precedence descening (higher to lower)
        .order(function(a : BinOp, b : BinOp) : Int {
          return b.precedence - a.precedence;
        })
        .map(function(binOp : BinOp) : Parser<AnnotatedExprBinOp<V, A>> {
          return index().flatMap(index ->
            ows
              .then(regexp(binOp.operatorRegexp))
              .map(operatorString -> (left, right) -> ae(EBinOp(operatorString, binOp.precedence, left, right), meta(index)))
          );
        });

    // Add binary op parsers in order of precedence
    expr = lazy(() ->
      exprBinOps.reduce(function(term : Parser<AnnotatedExpr<V, A>>, binOp : Parser<AnnotatedExprBinOp<V, A>>) {
        return term.chainl1(binOp);
      }, exprBaseTerm)
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
