/** @file bigbrother.d
@brief BigBrother system wrappers
@author Matthew Soucy <msoucy@csh.rit.edu>
@date May 9, 2012
@version 0.0.1
*/
/// BigBrother system wrappers
module bigbrother;

import std.array, std.algorithm, std.string;

import dzmq, protocol, devices;

/**
Store and parse a BigBrother message

@brief BigBrother message wrapper
@author Matthew Soucy <msoucy@csh.rit.edu>
@date May 9, 2012
*/
struct BBMessage {
	/// Topic of the message
	string topic;
	/// List of all hubs that the message has visited
	string[] routes;
	/// Message body
	string data;
	
	/// Protocol-ready form of the routing information
	@property string routing() {
		return routes.join(":");
	}
}


/**
Receive a BigBrother message via a socket

Receives and forms a BBMessage from the provided socket

@brief BigBrother message receiver
@authors Matthew Soucy <msoucy@csh.rit.edu>
@date May 9, 2012
*/
BBMessage recv_bb(Socket s, int flags=0) {
	string[] raw = s.recv_multipart(flags);
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

@brief BigBrother message sender
@author Matthew Soucy <msoucy@csh.rit.edu>
@date May 9, 2012
*/
void send_bb(Socket s, BBMessage msg, int flags=0) {
	s.send_multipart([msg.topic, msg.routing, msg.data], flags);
}


/// BigBrother Hub class
/**
Handles a BigBrother hub according to the specification

@author Matthew Soucy <msoucy@csh.rit.edu>
@date May 9, 2012
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
			if(msg.routes.canFind(this.name)) {
				// It's already been through this hub once
				forward = false;
			} else if(msg.topic == PROTOCOL) {
				// Handle PROTOCOL messages
				auto parsed = new BBProtocol(msg.data);
				forward = parsed.forward;
				if(parsed.listen != "") {
					// It contains a Listen command
					sub.connect(parsed.listen);
				}
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
	@brief Subscribe to a specific server
	@param addr The address of the server to subscribe to
	*/
	void subscribe_server(string addr) {
		// It'll automatically throw a ZMQError if the address is invalid
		this.sub.connect(addr);
	}
	/**
	@brief Publish to a specific server
	@param addr The address of the server to publish to
	*/
	void publish_server(string addr) {
		// It'll automatically throw a ZMQError if the address is invalid
		this.sub.connect(addr);
	}
}
