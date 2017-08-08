package haxpression2.schema;

import Parsihax;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

import haxpression2.parse.ParseMeta;

class ParseMetaSchema {
  public static function schema<E>() : Schema<E, ParseMeta> {
    return object(ap1(
      ParseMeta.new,
      required("index", indexSchema(), (meta : ParseMeta) -> meta.index)
    ));
  }

  public static function indexSchema<E>() : Schema<E, Index> {
    return object(ap3(
      (offset : Int, line : Int, column : Int) -> { offset: offset, line: line, column: column },
      required("offset", int(), (index : Index) -> index.offset),
      required("line", int(), (index : Index) -> index.line),
      required("column", int(), (index : Index) -> index.column)
    ));
  }
}
