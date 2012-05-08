module protocol;

import std.json, std.string, std.array, std.bitmanip;

// Protocol string
immutable PROTOCOL = "BigBrother-PROTOCOL";

private {
	T jsonExpect(T : int)(JSONValue v) {
		if(v.type == JSON_TYPE.INTEGER) return v.integer;
		else throw new JSONException("Improper type");
	}
	T jsonExpect(T : bool)(JSONValue v) {
		if(v.type == JSON_TYPE.INTEGER) return v.integer != 0;
		else if(v.type == JSON_TYPE.FALSE) return false;
		else if(v.type == JSON_TYPE.TRUE) return true;
		else throw new JSONException("Improper type");
	}
	T jsonExpect(T : real)(JSONValue v) {
		if(v.type == JSON_TYPE.INTEGER) return v.integer;
		else if(v.type == JSON_TYPE.FLOATING) return v.floating;
		else throw new JSONException("Improper type");
	}
	T jsonExpect(T : string)(JSONValue v) {
		if(v.type == JSON_TYPE.STRING) return v.str;
		else throw new JSONException("Improper type");
	}
	T jsonExpect(T: T[string])(JSONValue v) {
		// We're looking for an object
		if(v.type != JSON_TYPE.ARRAY) throw new JSONException("Improper type");
		T[string] ret;
		foreach(name, va;v.object) {
			ret[name] = jsonExpect!T(va);
		}
		return ret;
	}
	T[] jsonExpect(T: T[])(JSONValue v) {
		// We're looking for an array of T
		if(v.type != JSON_TYPE.ARRAY) throw new JSONException("Improper type");
		T[] ret;
		foreach(va;v.array) {
			ret ~= jsonExpect!T(va);
		}
		return ret;
	}
	
	/**
	 * Unescape certain things that JSON really doesn't like
	 * TODO: Incomplete
	 */
	string unescape(string source) {
		//return source.replace("\\","\\\\").replace(`"`,`\"`);
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
}

interface JSONProtocol {
	void json(string);
	string json();
}

class BBProtocol : JSONProtocol{
	public {
		bool forward;
		string listen;
		string ver;
	}
	this(string raw) {
		this.json(raw);
	}
	void json(string raw) {
		auto js = parseJSON(raw);
		assert(js.type == JSON_TYPE.OBJECT);
		if("forward" in js.object) {
			forward = jsonExpect!bool(js.object["forward"]);
		}
		// Keepalive flag is implicitly ignored - it detected this message, after all
		if("listen" in js.object) {
			listen = jsonExpect!string(js.object["listen"]);
		}
		if("version" in js.object) {
			ver = jsonExpect!string(js.object["version"]);
		}
	}
	string json() {
		return format(`{"forward" : %s, "listen" : "%s", "version" : "%s"}`,
			forward, listen.unescape(), ver.unescape());
	}
}
