module bigbrother;

import std.array, std.algorithm;

import dzmq, protocol;

void send_topic(Socket s, string topic, string msg, int flags=0) {
	s.send(topic, flags|Socket.Flags.SNDMORE);
	s.send(msg, flags);
}

string[] recv_topic(Socket s, out string topic, int flags=0) {
	string tmptopic = s.recv(flags);
	scope(success) topic = tmptopic;
	if(s.more) return s.recv_multipart(flags);
	else return [];
}

void send_bb(Socket s, BBMessage msg, int flags=0) {
		s.send_multipart([msg.topic, msg.routing, msg.data], flags);
}

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

struct BBMessage {
	string topic;
	string[] routes;
	@property string routing() {
		return routes.join(":");
	}
	string data;
}

class BBHub {
	private {
		string name;
		Socket pub, sub;
		Context cxt;
	}
	this(Context cxt, string name) {
		this.cxt = cxt;
		this.name = name;
		pub = new Socket(cxt, Socket.Type.PUB);
		pub.bind("tcp://*:5667");
		sub = new Socket(cxt, Socket.Type.SUB);
		sub.bind("tcp://*:5668");
		sub.subscribe(PROTOCOL);
		sub.subscribe("");
	}
	
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
}
