package haxpression2.compile;

import haxe.ds.Option;

using thx.Arrays;
using thx.Functions;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;

import haxpression2.Value;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.parse.ParseMeta;

enum DataType<V> {
  DTNum<F : Float> : DataType<ONumber<F>>;
  DTBool : DataType<OBool>;
  DTStr : DataType<OString>;
  DTSpan : DataType<Span>;
}

enum TimeUnit {
  Year;
  Month;
  Day;
}

enum Span {
  Span(v : Float, unit : TimeUnit);
}

enum ONumber<V : Float> {
  NNA : ONumber<V>;
  NNM : ONumber<V>;
  NVal(v : V) : ONumber<V>;
}

enum OString {
  SNA;
  SNM;
  SVal(v : String);
}

enum OBool {
  BNA;
  BNM;
  BVal(v : Bool);
}

enum FuncType<V> {
  ToFloat(operand : AnnotatedCompiledExpr<ONumber<Int>, ParseMeta>) : FuncType<ONumber<Float>>;
  Round(operand : AnnotatedCompiledExpr<ONumber<Float>, ParseMeta>) : FuncType<ONumber<Int>>;
  Floor(operand : AnnotatedCompiledExpr<ONumber<Float>, ParseMeta>) : FuncType<ONumber<Int>>;
  Ceil(operand : AnnotatedCompiledExpr<ONumber<Float>, ParseMeta>) : FuncType<ONumber<Int>>;
  Coalesce<U>(args : Array<AnnotatedCompiledExpr<U, ParseMeta>>) : FuncType<U>;
  CAGR(operand : AnnotatedCompiledExpr<ONumber<Float>, ParseMeta>, span : AnnotatedCompiledExpr<Span, ParseMeta>) : FuncType<ONumber<Float>>;
}

enum NumBinOpType<T : Float> {
  Add(left : AnnotatedCompiledExpr<ONumber<T>, ParseMeta>, right : AnnotatedCompiledExpr<ONumber<T>, ParseMeta>) : NumBinOpType<T>;
}

enum BoolBinOpType {
  And(left : AnnotatedCompiledExpr<OBool, ParseMeta>, right : AnnotatedCompiledExpr<OBool, ParseMeta>);
}

enum CompiledExpr<T> {
  CELit(value : T) : CompiledExpr<T>;
  CEVar(dataType : DataType<T>, name : String) : CompiledExpr<T>;
  CEFunc(funcType : FuncType<T>) : CompiledExpr<T>;
  CENumBinOp<U : Float>(binOpType : NumBinOpType<U>) : CompiledExpr<ONumber<U>>;
  CEBoolBinOp(binOpType : BoolBinOpType) : CompiledExpr<OBool>;
}

class AnnotatedCompiledExpr<T, A> {
  public var compiledExpr(default, null) : CompiledExpr<T>;
  public var annotation(default, null) : A;

  public function new(compiledExpr, annotation) {
    this.compiledExpr = compiledExpr;
    this.annotation = annotation;
  }
}

enum AnnotatedCompiledExprCapture<A> {
  CE<T>(dataType : DataType<T>, compiledExpr : AnnotatedCompiledExpr<T, A>);// : AnnotatedCompiledExprCapture<A>;
}

class CompileError extends thx.Error {
  public var parseMeta(default, null) : ParseMeta;
  public function new(message : String, parseMeta: ParseMeta, ?stack : Array<haxe.CallStack.StackItem>, ?pos : haxe.PosInfos) {
    super(message, stack, pos);
    this.parseMeta = parseMeta;
  }
  public override function toString() : String {
    return '$message (position: ${parseMeta.index.offset})';
  }
}

class CompileMeta {
  public var parseMeta(default, null) : ParseMeta;
  public function new(parseMeta) {
    this.parseMeta = parseMeta;
  }
}

typedef ExprCompilerOptions<V> = {
  compileLit :
    V ->
    ParseMeta ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>,

  compileVar :
    String ->
    ParseMeta ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>,

  compileFunc :
    String ->
    Array<AnnotatedExpr<V, ParseMeta>> ->
    ParseMeta ->
    ExprCompilerOptions<V> ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>,

  compileBinOp :
    String ->
    Int ->
    AnnotatedExpr<V, ParseMeta> ->
    AnnotatedExpr<V, ParseMeta> ->
    ParseMeta ->
    ExprCompilerOptions<V> ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>,

  compileUnOpPre :
    String ->
    Int ->
    AnnotatedExpr<V, ParseMeta> ->
    ParseMeta ->
    ExprCompilerOptions<V> ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>
};

enum ExprStringCompilerResult<V> {
  ParseError(error : ParseError<AnnotatedExpr<V, ParseMeta>>);
  CompileErrors(errors : Nel<CompileError>);
  Compiled(compiledExpr : AnnotatedCompiledExprCapture<ParseMeta>);
}

class ExprCompiler {
  public static function compile<V>(ae : AnnotatedExpr<V, ParseMeta>, options : ExprCompilerOptions<V>) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch ae.expr {
      case ELit(value) : options.compileLit(value, ae.annotation);
      case EVar(name) : options.compileVar(name, ae.annotation);
      case EBinOp(op, prec, left, right) : options.compileBinOp(op, prec, left, right, ae.annotation, options);
      case EFunc(name, args) : options.compileFunc(name, args, ae.annotation, options);
      case EUnOpPre(op, prec, operand) : options.compileUnOpPre(op, prec, operand, ae.annotation, options);
    }
  }

  public static function parseAndCompile<N>(
    input : String,
    parserOptions: ExprParserOptions<Value<N>, N, ParseMeta>,
    compilerOptions: ExprCompilerOptions<Value<N>>
  ) : ExprStringCompilerResult<Value<N>> {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(parseError) : ParseError(parseError);
      case Right(ae) : switch compile(ae, compilerOptions) {
        case Left(compileError) : CompileErrors(compileError);
        case Right(compiledExpr) : Compiled(compiledExpr);
      }
    };
  }

  public static function getSimpleExprCompilerOptions() : ExprCompilerOptions<Value<Float>> {
    return {
      compileLit: compileLit,
      compileVar: compileVar,
      compileFunc: compileFunc,
      compileBinOp: compileBinOp,
      compileUnOpPre: compileUnOpPre
    };
  }

  public static function compileLit<V>(value : Value<Float>, meta : ParseMeta) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch value {
      // TODO: assume NA and NM are of the Number type if no other context is given
      case VNA : successNel(CE(DTNum, new AnnotatedCompiledExpr(CELit(NNA), meta)));
      case VNM : successNel(CE(DTNum, new AnnotatedCompiledExpr(CELit(NNM), meta)));
      case VInt(v) : successNel(CE(DTNum, new AnnotatedCompiledExpr(CELit(NVal(v)), meta)));
      case VNum(v) : successNel(CE(DTNum, new AnnotatedCompiledExpr(CELit(NVal(v)), meta)));
      case VBool(v) : successNel(CE(DTBool, new AnnotatedCompiledExpr(CELit(BVal(v)), meta)));
      case VStr(v) : successNel(CE(DTStr, new AnnotatedCompiledExpr(CELit(SVal(v)), meta)));
    };
  }

  public static function compileVar(name : String, meta : ParseMeta) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    // Assume all variables are of type Number, otherwise we need a lookup map from variable to type, or some other naming convention
    return successNel(CE(DTNum, new AnnotatedCompiledExpr(CEVar(DTNum, name), meta)));
  }

  public static function compileFunc(
    name : String,
    args : Array<AnnotatedExpr<Value<Float>, ParseMeta>>,
    meta : ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch name {
      case "COALESCE": compileFuncCoalesce(name, args, meta, options);
      case "CAGR": compileFuncCAGR(name, args, meta, options).map(ace -> CE(DTNum, ace));
      case unk : failureNel(new CompileError('Unknown function: "${name}"', meta));
    };
  }

  public static function compileFuncCoalesce<V>(
    name : String,
    args : Array<AnnotatedExpr<Value<Float>, ParseMeta>>,
    meta : ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return args.traverseValidation(arg -> ExprCompiler.compile(arg, options), Nel.semigroup())
      .flatMapV(function(compiledArgs : Array<AnnotatedCompiledExprCapture<ParseMeta>>) {
        return if (compiledArgs.length == 0) {
          failureNel(new CompileError('Function "$name" must have at least one argument', meta));
        } else {
          switch compiledArgs[0] {
            case CE(DTNum, _) : compiledArgs.traverseValidation(ensureNumberExpr, Nel.semigroup()).map(args -> CE(DTNum, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
            case CE(DTStr, _) : compiledArgs.traverseValidation(ensureStringExpr, Nel.semigroup()).map(args -> CE(DTStr, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
            case CE(DTBool, _) : compiledArgs.traverseValidation(ensureBoolExpr, Nel.semigroup()).map(args -> CE(DTBool, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
            case CE(DTSpan, _) : compiledArgs.traverseValidation(ensureSpanExpr, Nel.semigroup()).map(args -> CE(DTSpan, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
          }
        }
      });
  }

  public static function compileFuncCAGR(name : String, args : Array<AnnotatedExpr<Value<Float>, ParseMeta>>, meta : ParseMeta, options: ExprCompilerOptions<Value<Float>>) : VNel<CompileError, AnnotatedCompiledExpr<ONumber<Float>, ParseMeta>> {
    return if (args.length != 2) {
      failureNel(new CompileError('"CAGR" function requires exactly two arguments', meta));
    } else {
      return val2(
        function(number, span) {
          return new AnnotatedCompiledExpr(CEFunc(CAGR(number, span)), meta);
        },
        ExprCompiler.compile(args[0], options).flatMapV(ensureNumberExpr),
        ExprCompiler.compile(args[1], options).flatMapV(ensureSpanExpr),
        Nel.semigroup()
      );
    }
  }

  public static function compileBinOp(
    operator : String,
    precedence : Int,
    left : AnnotatedExpr<Value<Float>, ParseMeta>,
    right : AnnotatedExpr<Value<Float>, ParseMeta>,
    meta: ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch operator {
      case "+" : compileBinOpNumberAdd(operator, precedence, left, right, meta, options).map(ace -> CE(DTNum, ace));
      case unk : failureNel(new CompileError('Unknown binary operator: \"$operator\"', meta));
    }
  }

  public static function compileBinOpNumberAdd<V : Float>(
    operator : String,
    precedence : Int,
    left : AnnotatedExpr<Value<Float>, ParseMeta>,
    right : AnnotatedExpr<Value<Float>, ParseMeta>,
    meta: ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExpr<ONumber<V>, ParseMeta>> {
    return val2(
      function(left : AnnotatedCompiledExpr<ONumber<V>, ParseMeta>, right : AnnotatedCompiledExpr<ONumber<V>, ParseMeta>) : AnnotatedCompiledExpr<ONumber<V>, ParseMeta> {
        return new AnnotatedCompiledExpr(CENumBinOp(Add(left, right)), meta);
      },
      ExprCompiler.compile(left, options).flatMapV(ensureNumberExpr),
      ExprCompiler.compile(right, options).flatMapV(ensureNumberExpr),
      Nel.semigroup()
    );
  }

  public static function compileUnOpPre<V>(
    operator : String,
    precedence : Int,
    operand : AnnotatedExpr<Value<Float>, ParseMeta>,
    meta: ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch operator {
      case unk : failureNel(new CompileError('Unknown prefix unary operator: \"$operator\"', meta));
    }
  }

  public static function ensureNumberExpr<U, V : Float>(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<ONumber<V>, ParseMeta>> {
    return switch acec {
      case CE(DTNum, ace) : successNel(ace);
      case CE(DTStr, ace) : failureNel(new CompileError('Expected a number expression, but found a string expression', ace.annotation));
      case CE(DTBool, ace) : failureNel(new CompileError('Expected a number expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a number expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureStringExpr<U, V : Float>(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<OString, ParseMeta>> {
    return switch acec {
      case CE(DTNum, ace) : failureNel(new CompileError('Expected a string expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : successNel(ace);
      case CE(DTBool, ace) : failureNel(new CompileError('Expected a string expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a string expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureBoolExpr<U, V : Float>(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<OBool, ParseMeta>> {
    return switch acec {
      case CE(DTNum, ace) : failureNel(new CompileError('Expected a bool expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : failureNel(new CompileError('Expected a bool expression, but found a string expression', ace.annotation));
      case CE(DTBool, ace) : successNel(ace);
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a bool expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureSpanExpr<U, V : Float>(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<Span, ParseMeta>> {
    return switch acec {
      case CE(DTNum, ace) : failureNel(new CompileError('Expected a span expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : switch ace.compiledExpr {
        case CELit(SVal(str)) : parseSpan(str, ace.annotation).map(span -> new AnnotatedCompiledExpr(CELit(span), ace.annotation));
        case CELit(SNA) : failureNel(new CompileError('span argument cannot be string literal NA value', ace.annotation));
        case CELit(SNM) : failureNel(new CompileError('span argument cannot be string literal NM value', ace.annotation));
        case CEVar(_) : failureNel(new CompileError('span argument must be a string literal', ace.annotation));
        case CEFunc(_) : failureNel(new CompileError('span argument must be a string literal', ace.annotation));
      };
      case CE(DTBool, ace) : failureNel(new CompileError('Expected a span expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : successNel(ace);
    }
  }

  public static function parseSpan(str : String, meta : ParseMeta) : VNel<CompileError, Span> {
    var regex = ~/(\d+)([ymd])/i;
    return if (regex.match(str)) {
      var intPart : Int = Std.parseInt(regex.matched(1));
      var unitPart = regex.matched(2);
      switch unitPart.toLowerCase() {
        case "y" : successNel(Span(intPart, Year));
        case "m" : successNel(Span(intPart, Month));
        case "d" : successNel(Span(intPart, Day));
        case _ : throw new thx.Error('should not happen');
      }
    } else {
      failureNel(new CompileError('string "$str" is not a valid span string', meta));
    }
  }

  public static function ensureAllSameType<U, V>(acecs : Array<AnnotatedCompiledExprCapture<ParseMeta>>, meta : ParseMeta) : VNel<CompileError, Array<AnnotatedCompiledExprCapture<ParseMeta>>> {
    return if (acecs.length <= 1) {
      successNel(acecs);
    } else {
      var first = acecs[0];
      var allSame = acecs.all(function(acec : AnnotatedCompiledExprCapture<ParseMeta>) : Bool {
        return switch [acec, first] {
          case [CE(DTNum, _), CE(DTNum, _)] : true;
          case [CE(DTStr, _), CE(DTStr, _)] : true;
          case [CE(DTBool, _), CE(DTBool, _)] : true;
          case [CE(DTSpan, _), CE(DTSpan, _)] : true;
          case [CE(DTNum, _), CE(_, _)] : false;
          case [CE(DTStr, _), CE(_, _)] : false;
          case [CE(DTBool, _), CE(_, _)] : false;
          case [CE(DTSpan, _), CE(_, _)] : false;
        };
      });
      return if (allSame) {
        successNel(acecs);
      } else {
        failureNel(new CompileError('arguments must all be of the same data type', meta));
      }
    }
  }
}
