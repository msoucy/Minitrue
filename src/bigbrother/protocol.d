/** @file protocol.d
@brief BigBrother protocol data
@author Matthew Soucy <msoucy@csh.rit.edu>
@date May 10, 2012
@version 0.0.1
*/
///BigBrother Protocol data
module protocol;

import std.json, std.string;

import jparse;

/// Protocol identifier
immutable PROTOCOL = "BigBrother-PROTOCOL";
/// Protocol version
immutable PROTOVER = "0.0.1";

/**
Interface for all message protocols

This is a simple interface to provide a standard system for
BigBrother JSON, to allow programs to handle multiple protocols
with ease.

@brief Protocol interface
@authors Matthew Soucy, msoucy@csh.rit.edu
@date May 9, 2012
*/
interface Protocol {
	/**
	Convert a JSON string into a Property
	Implementations should attempt to fill in any fields that
	they need or want.
	
	@brief Form a protocol from a JSON string
	@authors Matthew Soucy, msoucy@csh.rit.edu
	@date May 9, 2012
	*/
	@property void json(string);
	/**
	Convert a Property back into a JSON string
	This should fill in any fields that the protocol requires or uses.
	
	@brief Form a JSON string from a protocol
	@authors Matthew Soucy, msoucy@csh.rit.edu
	@date May 9, 2012
	*/
	@property string json();
	/**
	Create a string that is designed to be human-readable
	
	Convert a Property back into a JSON string
	This should fill in any fields that the protocol requires or uses.
	
	@authors Matthew Soucy, msoucy@csh.rit.edu
	@date May 9, 2012
	*/
	string pretty();
}

/**
BigBrother protocol class

Wraps a standard BigBrother-PROTOCOL message and turns it into a useful class

@authors Matthew Soucy, msoucy@csh.rit.edu
@date May 9, 2012
*/
class BBProtocol : Protocol {
	public {
		/// Whether this message should be forwarded
		bool forward;
		/// Address to subscribe to
		string listen;
		/// Protocol version
		string ver = PROTOVER;
	}
	/**
	Fill the fields upon creation
	@param raw Raw JSON string to parse
	*/
	this(string raw) {
		this.json = raw;
	}
	/**
	@brief Convert a JSON string into a Protocol 
	@param raw Raw JSON string to parse
	*/
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
	/**
	@brief Convert a message back into JSON
	@returns A completely filled JSON string
	*/
	@property string json() {
		return `{"forward" : %s, "listen" : "%s", "version" : "%s"}`
			.format(forward, listen.unescape(), ver.unescape());
	}
	/**
	@brief Format data to be human-readable
	@returns A formatted string
	*/
	string pretty() {
		return json();
	}
}
