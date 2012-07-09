/** @file protocol.d
@brief BigBrother protocol classes and handlers
@author Matthew Soucy <msoucy@csh.rit.edu>
@date May 10, 2012
@version 0.0.1
*/

/// BigBrother protocol data
module protocol;

/// @cond NoDoc
// Import JSON helping stuff
import jparse;
/// @endcond

/// Protocol identifier
immutable PROTOCOL = "BigBrother-PROTOCOL";
/// Protocol version
immutable PROTOVER = "0.0.1";

/** @interface Protocol
@brief Interface for all message protocols

This is a simple interface to provide a standard system for
BigBrother JSON, to allow programs to handle multiple protocols
with ease.

@authors Matthew Soucy, msoucy@csh.rit.edu
@date May 9, 2012
*/
interface Protocol {
	/** @property json(string raw)
	Convert a JSON string into a Property
	Implementations should attempt to fill in any fields that
	they need or want.
	
	@param[in] raw The raw JSON to read and parse
	
	@brief Form a protocol from a JSON string
	@authors Matthew Soucy, msoucy@csh.rit.edu
	@date May 9, 2012
	*/
	@property void json(string raw);
	
	/** @property json
	Convert a Protocol back into a JSON string
	This should fill in any fields that the protocol requires or uses.
	
	@returns The JSON string containing the values in the message
	
	@brief Form a JSON string from a protocol
	@authors Matthew Soucy, msoucy@csh.rit.edu
	@date May 9, 2012
	*/
	@property string json();
	
	/**
	Create a string that is designed to be human-readable
	
	Convert a Protocol back into a JSON string
	This should fill in any fields that the protocol requires or uses.
	
	@returns A human-readable string
	
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
	/// Whether this message should be forwarded
	public bool forward;
	/// Action to do
	public string command;
	/// Data to be used by the command
	public string data;
	/// Protocol version
	public string ver = PROTOVER;
	
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
		if("command" in js.object) {
			command = js.object["command"].expect!string;
		}
		if("data" in js.object) {
			ver = js.object["data"].expect!string;
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
		return `{"forward" : %s, "command" : "%s", "data" : "%s", "version" : "%s"}`
			.format(forward, command.unescape(), data.unescape(), ver.unescape());
	}
	/**
	@brief Format data to be human-readable
	@returns A formatted string
	*/
	string pretty() {
		return json();
	}
}

