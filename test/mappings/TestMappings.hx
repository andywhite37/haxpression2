package mappings;

import utest.Assert;

using thx.Arrays;
import thx.Error;
using thx.Eithers;
using thx.Functions;
using thx.Maps;
import thx.Tuple;
import thx.Validation;
import thx.schema.ParseError as SchemaParseError;
using thx.schema.SchemaDynamicExtensions;
import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

using haxpression2.AnnotatedExprGroup;
import haxpression2.parse.ParseError;
import haxpression2.parse.ParseMeta;
import haxpression2.schema.ParseMetaSchema;
import haxpression2.simple.SimpleExpr;
import haxpression2.simple.SimpleValue;

class TestMappings {
  public var mappingsPath(default, null) : String;
  //public var group(default, null) : SimpleAnnotatedExprGroup<ParseMeta>;

  public function new() {
    this.mappingsPath = js.node.Path.join(js.Node.__dirname, "..", "test", "mappings", "mappings.json");
  }

  public function testMappings() {
    var start = haxe.Timer.stamp();

    trace("----- Mappings -----");

    // Read file
    start = traceStamp("Read mappings file start");
    var content : String = Mappings.readMappingsFileAsString(mappingsPath);
    traceStamp("Read mappings file end", start);

    // JSON parse string content
    start = traceStamp("JSON parse mappings file content start");
    var obj : {} = Mappings.jsonParseMappingsFileContent(content);
    traceStamp("JSON parse mappings file content end", start);

    // Schema parse raw obj
    start = traceStamp("Schema parse mappings object start");
    var mappings : Map<String, Mapping> = Mappings.schemaParseRawMappingsObj(obj).either.orThrow('failed to schema parse');
    traceStamp("Schema parse mappings object end", start);

    start = traceStamp("Extract raw exprs from mappings into fallback map start");
    var exprsMap : Map<String, Array<String>> = Mappings.extractRawExprsMap(mappings);
    traceStamp("Extract raw exprs from mappings into fallback map end", start);

    start = traceStamp("Parse expressions into expression group start");
    var group : SimpleAnnotatedExprGroup<ParseMeta> = Mappings.parseRawExprsMap(exprsMap).either.orThrow('failed to parse exprs');
    traceStamp("Parse expressions into expression group start", start);

    trace('Group variable count: ${group.getVarCount()}');

    // Analyze
    start = traceStamp("Analyze expressions start");
    var result = AnnotatedExprGroup.analyze(group, SimpleValueRenderer.renderString);
    traceStamp("Analyze expressions end", start);

    AnalyzeResult.logPlainString(result);

    //Assert.pass();
  }

  public inline function traceStamp(message : String, ?start : Float) : Float {
    var now = haxe.Timer.stamp();
    var timeMessage = if (start != null) {
      ' in ${now - start} seconds';
    } else {
      '';
    }
    trace('${message}${timeMessage}');
    return now;
  }
}

class Mappings {
  public static function schema<E>() : Schema<E, Map<String, Mapping>> {
    return dict(Mapping.schema());
  }

/*
  public static function loadMappingsExprGroup(path : String) : VNel<String, SimpleAnnotatedExprGroup<ParseMeta>> {
    return loadRawMappings(path)
      .passTo(parseRawMappings)
      .map(extractRawExprsMap)
      .flatMapV(parseRawExprsMap);
  }
  */

  public static function readMappingsFileAsString<E>(path : String) : String {
    return js.node.Fs.readFileSync(path, 'utf-8');
  }

  public static function jsonParseMappingsFileContent(content : String) : {} {
    return haxe.Json.parse(content);
  }

  public static function schemaParseRawMappingsObj<E>(obj : {}) : VNel<String, Map<String, Mapping>> {
    return Mappings.schema().parseDynamic(thx.Functions.identity, obj)
      .leftMap(parseErrors -> parseErrors.map(e -> e.toString()));
  }

  public static function extractRawExprsMap(mappings : Map<String, Mapping>) : Map<String, Array<String>> {
    return mappings.foldLeftWithKeys(function(acc : Array<Tuple<String, Array<String>>>, mappingId : String, mapping : Mapping) {
      return mapping.sections.reduce(function(acc : Array<Tuple<String, Array<String>>>, section : MappingSection) {
        return acc.concat(section.getExprTuples(mapping.namespace));
      }, acc);
    }, [])
    .toStringMap();
  }

  public static function parseRawExprsMap(mappings : Map<String, Array<String>>) : VNel<String, SimpleAnnotatedExprGroup<ParseMeta>> {
    return SimpleAnnotatedExprGroup.parseFallbackStringsMap(
      mappings,
      "COALESCE",
      SimpleExprs.getStandardExprParserOptions({ annotate: ParseMeta.new })
    )
    .leftMap(parseErrors -> parseErrors.map(e -> e.toString()));
  }
}

class Mapping {
  public var id(default, null) : String;
  public var name(default, null) : String;
  public var namespace(default, null) : String;
  public var from(default, null) : Array<String>;
  public var sections(default, null) : Array<MappingSection>;

  public function new(id, name, ns, from, sections) {
    this.id = id;
    this.name = name;
    this.namespace = ns;
    this.from = from;
    this.sections = sections;
  }

  public static function schema<E>() : Schema<E, Mapping> {
    return object(ap5(
      Mapping.new,
      required("id", string(), (mapping : Mapping) -> mapping.id),
      required("name", string(), (mapping : Mapping) -> mapping.name),
      required("namespace", string(), (mapping : Mapping) -> mapping.namespace),
      required("from", array(string()), (mapping : Mapping) -> mapping.from),
      required("sections", array(MappingSection.schema()), (mapping : Mapping) -> mapping.sections)
    ));
  }
}

class MappingSection {
  public var id(default, null) : String;
  public var sections(default, null) : Array<MappingSection>;
  public var items(default, null) : Array<MappingItem>;

  public function new (id, sections, items) {
    this.id = id;
    this.sections = sections;
    this.items = items;
  }

  public static function schema<E>() : Schema<E, MappingSection> {
    return object(ap3(
      MappingSection.new,
      required("id", string(), (s : MappingSection) -> s.id),
      required("sections", lazy(() -> array(MappingSection.schema()).schema), (s : MappingSection) -> s.sections),
      required("items", array(MappingItem.schema()), (s : MappingSection) -> s.items)
    ));
  }

  public function getExprTuples(namespace : String) : Array<Tuple<String, Array<String>>> {
    var acc = sections.reduce(function(acc : Array<Tuple<String, Array<String>>>, section: MappingSection) {
      return acc.concat(section.getExprTuples(namespace));
    }, []);

    acc = items.reduce(function(acc : Array<Tuple<String, Array<String>>>, item : MappingItem) {
      return acc.concat([item.getExprTuple(namespace)]);
    }, acc);

    return acc;
  }
}

class MappingItem {
  public var id(default, null) : String;
  public var name(default, null) : String;
  public var definition(default, null) : Array<String>;

  public function new(id, name, defs) {
    this.id = id;
    this.name = name;
    this.definition = defs;
  }

  public static function schema<E>() : Schema<E, MappingItem> {
    return object(ap3(
      MappingItem.new,
      required("id", string(), (i : MappingItem) -> i.id),
      required("name", string(), (i : MappingItem) -> i.name),
      required("definition", array(string()), (i : MappingItem) -> i.definition)
    ));
  }

  public function getExprTuple(namespace : String) : Tuple<String, Array<String>> {
    return new Tuple('${namespace}!${id}', definition);
  }
}
