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
		return source.replace("\\","\\\\").replace(`"`,`\"`);
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
		return format(`{"forward" : %s, "listen" : "%s", "version" : "%s"}`, forward, listen.unescape, ver.unescape);
	}
}

private template MakeMember(string local, T, string jname=local) { 
	enum MakeMember = T~` `~local~`\n`;
}

private template CheckMember(string local, string type, string jname=local) { 
	enum CheckMember = `if("`~jname~`" in js.object) {
	`~local~` = jsonExpect!`~type~`(js.object["`~jname~`"]);
}`;
}
