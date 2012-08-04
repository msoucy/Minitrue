import core.thread;
import core.time;

import std.stdio;
import std.string;

import dzmq, devices;
import bigbrother, protocol;

void smain() {
	Context context = new Context(1);
	
	// Socket to talk to server
	writef("Connecting to hello world server…\n");
	Socket requester = new Socket(context, Socket.Type.SUB);
	requester.connect("tcp://localhost:5668");
	requester.subscribe("ZMQTesting");
	
	while(1) {
		auto msg = requester.recv_bb();
		writef("Received %s: %s\n", msg.topic, msg.data);
		writef("\tRouting: %s\n", msg.routes);
	}
}

void pmain()
{
	Context context = new Context(1);
	
	// Socket to talk to clients
	Socket responder = new Socket(context, Socket.Type.PUB);
	responder.connect("tcp://localhost:5667");
	
	BBMessage msg;
	msg.topic = "ZMQTesting";
	
	ulong i=0;
	string data = "Init";
	while (1) {
		// Wait for next request from client
		//msg.data = format(`{"index":%d}`,i++);
		data = readln().strip();
		msg.data = format(`{"data":%s}`,data);
		responder.send_bb(msg);
		
		// Do some 'work'
		Thread.sleep(dur!"seconds"(1));
	}
}

void d1main()
{
	Context context = new Context(1);
	
	Hub hub = new Hub(context, "HubA", 5661, 5667);
	hub.run();
}

void d2main()
{
	Context context = new Context(1);
	
	Hub hub = new Hub(context, "HubB", 5668, 5662);
	hub.handle_command("subscribe", "tcp://127.0.0.1:5661");
	hub.run();
}

void main(string[] argv) {
	if(argv.length != 2) {
		stderr.writeln("Error: Invalid arguments");
		return;
	}
	switch(argv[1]) {
	case "pub": pmain();break;
	case "sub": smain();break;
	case "d1": d1main();break;
	case "d2": d2main();break;
	default: writef("Invalid parameter");break;
	}
}

