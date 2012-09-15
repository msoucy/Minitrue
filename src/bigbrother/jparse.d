/** @file jparse.d
@brief Parsing improvement system for std.json
@author Matthew Soucy <msoucy@csh.rit.edu>
@date May 9, 2012
@todo add more coercions
*/

/// JSON type improvement functions
module jparse;

/// @cond NoDoc
// Import json and string handlers
public import std.json, std.string, std.conv;
/// @endcond

/**
Coerce a JSONValue to a long if possible
@return Value stored in v
*/
@property long expect(T : long)(JSONValue v) {
	with(JSON_TYPE) switch(v.type) {
	case INTEGER: return v.integer;
	case FALSE: return 0;
	case TRUE: return 1;
	case FLOAT: return v.floating.roundTo!long;
	case STRING: try{
			return v.str.to!long;
		} catch(ConvException e) {
			throw new JSONException("Improper value");
		}
	case UINTEGER: if(v.uinteger>=long.max) return v.uinteger;
					else throw new JSONException("Value too large");
	default: throw new JSONException("Improper type");
	}
}
/**
Coerce a JSONValue to a ulong if possible
@return Value stored in v
*/
@property ulong expect(T : ulong)(JSONValue v) {
	with(JSON_TYPE) switch(v.type) {
	case INTEGER: if(v.integer>=0) return v.integer;
					else throw new JSONException("Improper value");
	case FALSE: return 0;
	case TRUE: return 1;
	case FLOAT: return v.floating.roundTo!long;
	case STRING: try{
			return v.str.to!ulong;
		} catch(ConvException e) {
			throw new JSONException("Improper value");
		}
	case UINTEGER: return v.uinteger;
	default: throw new JSONException("Improper type");
	}
}
/**
Coerce a JSONValue to a bool if possible
@return Value stored in v
*/
@property bool expect(T : bool)(JSONValue v) {
	with(JSON_TYPE) switch(v.type) {
	case INTEGER: return v.integer != 0;
	case NULL, FALSE: return false;
	case TRUE: return true;
	case FLOAT: return v.floating != 0.0;
	case STRING: return v.str != "";
	case UINTEGER: return v.uinteger != 0;
	case ARRAY: return v.array.length != 0;
	default: throw new JSONException("Improper type");
	}
}
/**
Coerce a JSONValue to a real if possible
@return Value stored in v
*/
@property real expect(T : real)(JSONValue v) {
	with(JSON_TYPE) switch(v.type) {
	case INTEGER: return v.integer;
	case FALSE: return 0;
	case TRUE: return 1;
	case FLOAT: return v.floating;
	case STRING: try{
			return v.str.to!real;
		} catch(ConvException e) {
			throw new JSONException("Improper value");
		}
	case UINTEGER: return v.uinteger;
	case NULL: return real.nan;
	default: throw new JSONException("Improper type");
	}
}
/**
Coerce a JSONValue to a string if possible
@return Value stored in v
*/
@property string expect(T : string)(JSONValue v) {
	with(JSON_TYPE) switch(v.type) {
	case INTEGER: return "%s".format(v.integer);
	case FALSE: return "false";
	case TRUE: return "true";
	case FLOAT: return "%s".format(v.floating);
	case STRING: return v.str;
	case UINTEGER: return "%s".format(v.uinteger);
	case NULL: return "null";
	case OBJECT: return "%s".format(v.object);
	case ARRAY: return "%s".format(v.array);
	default: throw new JSONException("Improper type");
	}
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
		ret[name] = va.expect!T;
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

