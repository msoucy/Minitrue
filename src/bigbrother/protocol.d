module protocol;

import std.json, std.string, std.array, std.bitmanip;

// Protocol string
immutable PROTOCOL = "BigBrother-PROTOCOL";

@property private {
	T expect(T : int)(JSONValue v) {
		if(v.type == JSON_TYPE.INTEGER) return v.integer;
		else throw new JSONException("Improper type");
	}
	T expect(T : bool)(JSONValue v) {
		if(v.type == JSON_TYPE.INTEGER) return v.integer != 0;
		else if(v.type == JSON_TYPE.FALSE) return false;
		else if(v.type == JSON_TYPE.TRUE) return true;
		else throw new JSONException("Improper type");
	}
	T expect(T : real)(JSONValue v) {
		if(v.type == JSON_TYPE.INTEGER) return v.integer;
		else if(v.type == JSON_TYPE.FLOATING) return v.floating;
		else throw new JSONException("Improper type");
	}
	T expect(T : string)(JSONValue v) {
		if(v.type == JSON_TYPE.STRING) return v.str;
		else throw new JSONException("Improper type");
	}
	T expect(T: T[string])(JSONValue v) {
		// We're looking for an object
		if(v.type != JSON_TYPE.ARRAY) throw new JSONException("Improper type");
		T[string] ret;
		foreach(name, va;v.object) {
			ret[name] = expect!T(va);
		}
		return ret;
	}
	T[] expect(T: T[])(JSONValue v) {
		// We're looking for an array of T
		if(v.type != JSON_TYPE.ARRAY) throw new JSONException("Improper type");
		T[] ret;
		foreach(va;v.array) {
			ret ~= expect!T(va);
		}
		return ret;
	}
}

/**
 * Unescape certain things that JSON really doesn't like
 * TODO: Incomplete
 */
string unescape(string source) {
	string ret;
	foreach(char ch;source) {
		switch (ch) {
            case '"': ret ~= `\"`; break;
            case '\\': ret ~= `\\`; break;
            case '/': ret ~= `\/`; break;
            case '\b': ret ~= `\b`; break;
            case '\f': ret ~= `\f`; break;
            case '\n': ret ~= `\n`; break;
            case '\r': ret ~= `\r`; break;
            case '\t': ret ~= `\t`; break;
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

/**
Protocol interface

Interface for all message protocols

This is a simple interface to provide a standard system for
BigBrother JSON, to allow programs to handle multiple protocols
with ease.

@authors Matthew Soucy, msoucy@csh.rit.edu
@date May 9, 2012
*/
interface Protocol {
	/**
	Property to convert from json
	
	Property that forms a Protocol from a JSON string
	
	Convert a JSON string into a Property
	Implementations should attempt to fill in any fields that
	they need or want.
	
	@authors Matthew Soucy, msoucy@csh.rit.edu
	@date May 9, 2012
	*/
	@property void json(string);
	/**
	Property to convert to json
	
	Property that forms a JSON string from a protocol
	
	Convert a Property back into a JSON string
	This should fill in any fields that the protocol requires or uses.
	
	@authors Matthew Soucy, msoucy@csh.rit.edu
	@date May 9, 2012
	*/
	@property string json();
	/**
	Pretty print the internal values
	
	Create a string that is designed to be human-readable
	
	Convert a Property back into a JSON string
	This should fill in any fields that the protocol requires or uses.
	
	@authors Matthew Soucy, msoucy@csh.rit.edu
	@date May 9, 2012
	*/
	string pretty();
}

class BBProtocol : Protocol {
	public {
		bool forward;
		string listen;
		string ver;
	}
	this(string raw) {
		this.json = raw;
	}
	@property void json(string raw) {
		auto js = parseJSON(raw);
		assert(js.type == JSON_TYPE.OBJECT);
		if("forward" in js.object) {
			forward = js.object["forward"].expect!bool;
		}
		// Keepalive flag is implicitly ignored - it detected this message, after all
		if("listen" in js.object) {
			listen = js.object["listen"].expect!string;
		}
		if("version" in js.object) {
			ver = js.object["version"].expect!string;
		}
	}
	@property string json() {
		return format(`{"forward" : %s, "listen" : "%s", "version" : "%s"}`,
			forward, listen.unescape(), ver.unescape());
	}
	string pretty() {
		return json();
	}
}
