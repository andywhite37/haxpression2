package haxpression2.render;

using thx.schema.SchemaDynamicExtensions;
import thx.schema.SimpleSchema;

class JSONRenderer {
  public static function renderJSONString<E, V>(schema : Schema<E, V>, value : V, ?pretty: Bool = true) : String {
    var dyn = schema.renderDynamic(value);
    return haxe.Json.stringify(dyn, null, pretty ? '  ' : '');
  }
}
