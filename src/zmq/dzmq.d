module dzmq;

import std.string : toStringz;

import zmq;

class Context {
	private {
		void* _context;
	}
	this(int threads) {
		_context = zmq.zmq_init(threads);
	}
	~this() {
		zmq.zmq_term(_context);
	}
	alias _context this;
}

class Socket {
	private {
		Context context;
		void* _socket;
	}
	this(Context c, int type) {
		context = c;
		_socket = zmq_socket(context, type);
	}
	~this() {
		zmq_close(context);
	}
	int bind(string endpoint) {
		return zmq_bind(_socket, endpoint.toStringz());
	}
	int connect(string endpoint) {
		return zmq_connect(_socket, endpoint.toStringz());
	}
	alias _socket this;
}

class Message {
	
}