package haxpression2.parse;

using thx.Arrays;
import thx.Either;
using thx.Eithers;
using thx.Maps;
import thx.Nel;
import thx.Tuple;
import thx.Validation;
import thx.Validation.*;

import Parsihax.*;
using Parsihax;

import haxpression2.AnnotatedExpr;
import haxpression2.Expr;
import haxpression2.Value;
import haxpression2.parse.CoreParser.ows;
import haxpression2.parse.ParseError;

typedef ExprParserOptions<V, N, A> = {
  variableNameRegexp: EReg,
  functionNameRegexp: EReg,
  parseDecimal: String -> N,
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

    // Literal value parser
    var exprLit : Parser<AnnotatedExpr<V, A>> =
      index().flatMap(index ->
        valueParser.map(v -> ae(ELit(options.convertValue(v)), meta(index)))
      );

    // Variable parser
    var exprVar : Parser<AnnotatedExpr<V, A>> =
      index().flatMap(index ->
        options.variableNameRegexp.regexp().map(v -> ae(EVar(v), meta(index)))
      );

    // Function parser
    var exprFunc : Parser<AnnotatedExpr<V, A>> =
      index().flatMap(index ->
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
    var exprParen : Parser<AnnotatedExpr<V, A>> =
      index().flatMap(index ->
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
        .map(function(unOp : UnOp) : Parser<AnnotatedExpr<V, A>> {
          return ows.then(
            index().flatMap(index ->
              unOp.operatorRegexp.regexp()
                .flatMap(function(operatorString: String) {
                  return ows
                    .then(exprBaseTerm)
                    .map(ae -> new AnnotatedExpr(EUnOpPre(operatorString, unOp.precedence, ae), meta(index)));
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

  public static function parseString<V, N, A>(input : String, options : ExprParserOptions<V, N, A>) : Either<ParseError<AnnotatedExpr<V, A>>, AnnotatedExpr<V, A>> {
    var parseResult : Result<AnnotatedExpr<V, A>> = create(options).expr.skip(eof()).apply(input);
    return if (parseResult.status) {
      Right(parseResult.value);
    } else {
      Left(ParseError.fromParseResult(input, parseResult));
    };
  }

  public static function parseStrings<V, N, A>(input : Array<String>, options : ExprParserOptions<V, N, A>) : VNel<ParseError<AnnotatedExpr<V, A>>, Array<AnnotatedExpr<V, A>>> {
    return input.traverseValidation(function(str : String) {
      return parseString(str, options).toVNel();
    }, Nel.semigroup());
  }

  public static function parseStringMap<V, N, A>(input : Map<String, String>, options : ExprParserOptions<V, N, A>) : VNel<ParseError<AnnotatedExpr<V, A>>, Map<String, AnnotatedExpr<V, A>>> {
    return input
      .tuples()
      .traverseValidation(function(keyStr : Tuple<String, String>) : VNel<ParseError<AnnotatedExpr<V, A>>, Tuple<String, AnnotatedExpr<V, A>>> {
        return parseString(keyStr._1, options).map(ae -> new Tuple(keyStr._0, ae)).toVNel();
      }, Nel.semigroup())
      .map(function(tuples : Array<Tuple<String, AnnotatedExpr<V, A>>>) {
        return tuples.toStringMap();
      });
  }
}
