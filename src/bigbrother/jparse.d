/** @file jparse.d
Parsing improvement system for std.json

@author Matthew Soucy <msoucy@csh.rit.edu>
@date May 9, 2012
*/
///JSON type improvement functions
module jparse;

import std.json, std.string;

/**
Coerce a JSONValue to a long if possible
@return Value stored in v
*/
@property long expect(T : long)(JSONValue v) {
	if(v.type == JSON_TYPE.INTEGER) return v.integer;
	else throw new JSONException("Improper type");
}
/**
Coerce a JSONValue to a bool if possible
@return Value stored in v
*/
@property bool expect(T : bool)(JSONValue v) {
	if(v.type == JSON_TYPE.INTEGER) return v.integer != 0;
	else if(v.type == JSON_TYPE.FALSE) return false;
	else if(v.type == JSON_TYPE.TRUE) return true;
	else throw new JSONException("Improper type");
}
/**
Coerce a JSONValue to a real if possible
@return Value stored in v
*/
@property real expect(T : real)(JSONValue v) {
	if(v.type == JSON_TYPE.INTEGER) return v.integer;
	else if(v.type == JSON_TYPE.FLOATING) return v.floating;
	else throw new JSONException("Improper type");
}
/**
Coerce a JSONValue to a string if possible
@return Value stored in v
*/
@property string expect(T : string)(JSONValue v) {
	if(v.type == JSON_TYPE.STRING) return v.str;
	else throw new JSONException("Improper type");
}
/**
Coerce a JSONValue to an associative array of type T[string] if possible
@return Value stored in v
*/
@property T[string] expect(T: T[string])(JSONValue v) {
	// We're looking for an object
	if(v.type != JSON_TYPE.ARRAY) throw new JSONException("Improper type");
	T[string] ret;
	foreach(name, va;v.object) {
		ret[name] = expect!T(va);
	}
	return ret;
}
/**
Coerce a JSONValue to an array of T if possible
@return Value stored in v
*/
@property T[] expect(T: T[])(JSONValue v) {
	// We're looking for an array of T
	if(v.type != JSON_TYPE.ARRAY) throw new JSONException("Improper type");
	T[] ret;
	foreach(va;v.array) {
		ret ~= expect!T(va);
	}
	return ret;
}
