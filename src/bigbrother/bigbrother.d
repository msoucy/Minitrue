/** @file bigbrother.d
@brief BigBrother system wrappers
@author Matthew Soucy <msoucy@csh.rit.edu>
@date July 9, 2012
@version 0.0.1
*/

/// BigBrother system wrappers
module bigbrother;

/// @cond NoDoc
import std.array, std.algorithm, std.exception, std.json, std.string, std.stdio;
import dzmq, protocol, devices;
/// @endcond

/**
Store and parse a BigBrother message

@brief BigBrother message wrapper
@author Matthew Soucy <msoucy@csh.rit.edu>
*/
struct BBMessage {
	/// Topic of the message
	string topic;
	/// List of all hubs that the message has visited
	string[] routes;
	/// Message body
	string data;
	
	/** @property routing
	Protocol-ready form of the routing information
	Read-only
	@returns A \c : delimited list of server names
	*/
	@property string routing() {
		return routes.join(":");
	}
}


/**
Receive a BigBrother message via a socket

Receives and forms a BBMessage from the provided socket.
Designed with UFCS in mind.

@param sock The socket to receive a BBMessage from
@param flags The socket flags to use
@returns The BBMessage received

@brief BigBrother message receiver
@authors Matthew Soucy <msoucy@csh.rit.edu>
*/
BBMessage recv_bb(Socket sock, int flags=0) {
	string[] raw = sock.recv_multipart(flags);
	// We can verify this, since the BigBrother protocol requires it
	assert(raw.length == 3, "Invalid BigBrother packet");
	BBMessage msg = BBMessage();
	msg.topic = raw[0];
	msg.routes = raw[1].split(":");
	msg.data = raw[2];
	return msg;
}

/**
Send a BigBrother message via a socket

Sends an already created BBMessage via the Socket
Designed with UFCS in mind.

@param sock The socket to send a BBMessage with
@param msg The message to send
@param flags The socket flags to use

@brief BigBrother message sender
@author Matthew Soucy <msoucy@csh.rit.edu>
*/
void send_bb(Socket sock, BBMessage msg, int flags=0) {
	sock.send_multipart([msg.topic, msg.routing, msg.data], flags);
}


/**
@brief BigBrother Hub class

Handles a BigBrother hub according to the specification

@author Matthew Soucy <msoucy@csh.rit.edu>
*/
class Hub : devices.Device {
	private {
		string name;
		Socket pub, sub;
		Context cxt;
	}
	/**
	Prepare a hub and have it bind the required sockets
	
	@param cxt Context to use to initialize sockets 
	@param name Name of the hub
	@param pport Publisher port
	@param sport Subscriber port
	*/
	this(Context cxt, string name, uint pport=5667, uint sport=5668) {
		this.cxt = cxt;
		this.name = name;
		pub = new Socket(cxt, Socket.Type.PUB);
		pub.bind("tcp://*:%d".format(pport));
		sub = new Socket(cxt, Socket.Type.SUB);
		sub.bind("tcp://*:%d".format(sport));
		sub.subscribe(PROTOCOL);
		sub.subscribe("");
	}
	
	/**
	Start a Hub's main task
	
	This hub will receive and rebroadcast all messages.
	
	It also follows any instructions given in messages sent with the "BigBrother-PROTOCOL" topic.
	*/
	void run() {
		bool forward = true;
		while(this.cxt.raw != null) {
			BBMessage msg = sub.recv_bb();
			forward=true;
			try {
				auto parsed = parseJSON(msg.data);
				// Make sure it's an object or an array
				if(parsed.type == JSON_TYPE.OBJECT) {
					forward = process_message(msg);
				} else if(parsed.type == JSON_TYPE.ARRAY) {
					foreach(message;parsed.array) {
						// If not process_message, forward = false
						if(!process_message(BBMessage(toJSON(&message)))) {
							forward = false;
						}
					}
				} else {
					"Invalid protocol type".writeln();
					forward = false;
				}
			} catch(JSONException e) {
				// So it's invalid JSON.
			} catch(Exception e) {
				// Invalid protocol
			}
			
			if(forward) {
				// Add itself to the routing list
				msg.routes ~= this.name;
				pub.send_bb(msg, Socket.Flags.NOBLOCK);
			}
		}
		throw new ZMQError();
	}
	
	/**
	Handle Protocol messages
	@param cmd Command to parse
	@param data Data to pass to the command
	*/
	public void handle_command(string cmd, string data) {
		switch(cmd) {
			case "pass": break;
			case "subscribe": {
				this.sub.connect(data);
				break;
			}
			case "publish": {
				this.pub.connect(data);
				break;
			}
			default: break;
		}
	}
	
	/**
	Handle the actual work in a message.
	@returns true if the message should be forwarded
	*/
	private bool process_message(BBMessage msg) {
		bool forward = true;
		if(msg.routes.canFind(this.name)) {
			// It's already been through this hub once
			forward = false;
		} else if(msg.topic == PROTOCOL) {
			// Handle PROTOCOL messages
			auto parsed = new BBProtocol(msg.data);
			forward = parsed.forward;
			try {
				this.handle_command(parsed.command, parsed.data);
			} catch(ZMQError e) {
				// So we don't want the hub to shut down.
				// Let's just log a message.
				"Error: %s\n".writef(e.msg);
			}
		}
		return forward;
	}
}

