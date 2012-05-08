
import core.thread;
import core.time;

import std.stdio;
import std.string;

import dzmq, devices;
import bigbrother, protocol;

void cmain() {
	Context context = new Context(1);
	
	// Socket to talk to server
	writef("Connecting to hello world server…\n");
	Socket requester = new Socket(context, Socket.Type.SUB);
	requester.connect("tcp://localhost:5667");
	requester.subscribe("ZMQTesting");
	
	int request_nbr;
	for (request_nbr = 0; request_nbr != 10; request_nbr++) {
		auto msg = requester.recv_bb();
		writef("Received %s: %s (%d)\n", msg.topic, msg.data, request_nbr);
		writef("\tRouting: %s\n", msg.routing);
	}
}

void smain()
{
	Context context = new Context(1);
	
	// Socket to talk to clients
	Socket responder = new Socket(context, Socket.Type.PUB);
	responder.connect("tcp://*:5668");
	
	BBMessage msg;
	msg.topic = "ZMQTesting";
	
	int i=0;
	while (1) {
		// Wait for next request from client
		msg.data = format(`{"index":%d}`,i++);
		responder.send_bb(msg);
		
		// Do some 'work'
		Thread.sleep(dur!"seconds"(1));
	}
}

void dmain()
{
	Context context = new Context(1);
	
	/+
	// Socket to talk to clients
	Socket front = new Socket(context, Socket.Type.SUB);
	front.connect("tcp://localhost:5668");
	front.subscribe("");
	
	Socket back = new Socket(context, Socket.Type.PUB);
	back.bind("tcp://*:5667");
	
	auto dev = new ForwarderDevice(front, back);
	+/
	BBHub hub = new BBHub(context, "BB-hub");
	hub.run();
}

void jsontest() {
	stdout.flush();
	auto x = new BBProtocol(`{"version":"ABC\"DEF"}`);
	writef("%s\n", x.ver);
}

void main(string[] argv) {
	if(argv.length != 2) {
		stderr.writeln("Error: Invalid arguments");
		return;
	}
	if(argv[1] == "server") smain();
	else if(argv[1] == "client") cmain();
	else if(argv[1] == "device") dmain();
	else if(argv[1] == "json") jsontest();
}
