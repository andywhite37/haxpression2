package haxpression2.simple;

using haxpression2.render.ValueRenderer;

typedef SimpleValue = Value<Float>;

class SimpleValues {
  public static function renderString(value : SimpleValue) : String {
    return value.renderString(Std.string);
  }
}
