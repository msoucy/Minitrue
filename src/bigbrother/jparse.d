/** @file jparse.d
@brief Parsing improvement system for std.json
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


/**
Unescape certain things that JSON really doesn't like
@param source A raw string literal
@returns A JSON-safe string
*/
string unescape(string source) {
	string ret;
	foreach(char ch;source) {
		switch (ch) {
            case '"': ret ~= "\\\""; break;
            case '\\': ret ~= "\\\\"; break;
            case '/': ret ~= "\\/"; break;
            case '\b': ret ~= "\\b"; break;
            case '\f': ret ~= "\\f"; break;
            case '\n': ret ~= "\\n"; break;
            case '\r': ret ~= "\\r"; break;
            case '\t': ret ~= "\\t"; break;
            default: {
            	if(ch < 0x001F) {
            		ret ~= format("\\u%04x\n", ch);
            	} else {
            		ret ~= ch;
        		}
            	break;
        	}
        }
	}
	return ret;
}