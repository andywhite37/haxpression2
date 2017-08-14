package haxpression2.simple;

import thx.Either;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

import haxpression2.parse.ParseError;
import haxpression2.parse.ValueParser;
import haxpression2.render.ValueRenderer;
import haxpression2.schema.ValueSchema;

typedef SimpleValue = Value<Float>;

class SimpleValueSchema {
  public static function schema<E>() : Schema<E, SimpleValue> {
    return ValueSchema.schema(float());
  }
}

class SimpleValueParser {
  public static function parseString(input : String) : Either<ParseError<SimpleValue>, SimpleValue> {
    return ValueParser.parseString(input, { parseReal: Std.parseFloat });
  }
}

class SimpleValueRenderer {
  public static function renderString(value : SimpleValue) : String {
    return ValueRenderer.renderString(value, { realToString: Std.string });
  }
}
