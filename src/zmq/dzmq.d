module dzmq;

import std.string : toStringz, format;

import zmq;

version (win32)
{
    alias SOCKET socket_t;
} else {
    alias int socket_t;
}

alias extern(C) void function(void *data, void *hint) zmq_free_fn;

private template MakeSetFunc(string name, string type) {
	const char[] MakeSetFunc = type~` opt(int N:`~name~`)(`~name~` newval) {
	auto err = zmq_setsockopt(_socket, N, &newval, `~type~`.sizeof);
	if(err) {
		throw new ZMQError();
	} else {
		return newval;
	}
}`;
}
private template MakeGetFunc(string name, string type) {
	const char[] MakeGetFunc = type~` opt(int N:`~name~`)() {
	size_t len;
	int ret;
	auto err = zmq_getsockopt(_socket, N, &ret, &len);
	if(err) {
		throw new ZMQError();
	} else {
		assert(len==ret.sizeof);
		return ret;
	}
}`;
}
private template MakeFuncs(string name, string type) {
	const char[] MakeFuncs = MakeGetFunc!(name,type)~MakeSetFunc!(name,type);
}

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
	@property {
		// This is why string mixins are awesome
		// Get and Set
		mixin(MakeFuncs!("ZMQ_HWM", "ulong"));
		mixin(MakeFuncs!("ZMQ_SWAP", "long"));
		mixin(MakeFuncs!("ZMQ_AFFINITY", "ulong"));
		mixin(MakeFuncs!("ZMQ_IDENTITY", "ulong"));
		// These two don't have matching constants
		//mixin(MakeFuncs!("ZMQ_RCVTIMEO", "int"));
		//mixin(MakeFuncs!("ZMQ_SNDTIMEO", "int"));
		mixin(MakeFuncs!("ZMQ_RATE", "long"));
		mixin(MakeFuncs!("ZMQ_RECOVERY_IVL", "long"));
		mixin(MakeFuncs!("ZMQ_RECOVERY_IVL_MSEC", "long"));
		mixin(MakeFuncs!("ZMQ_MCAST_LOOP", "long"));
		mixin(MakeFuncs!("ZMQ_SNDBUF", "long"));
		mixin(MakeFuncs!("ZMQ_RCVBUF", "long"));
		mixin(MakeFuncs!("ZMQ_LINGER", "int"));
		mixin(MakeFuncs!("ZMQ_RECONNECT_IVL", "int"));
		mixin(MakeFuncs!("ZMQ_RECONNECT_IVL_MAX", "int"));
		mixin(MakeFuncs!("ZMQ_BACKLOG", "int"));
		
		// These ones are set-only
		mixin(MakeSetFunc!("ZMQ_SUBSCRIBE", "ulong"));
		mixin(MakeSetFunc!("ZMQ_UNSUBSCRIBE", "ulong"));
		
		// These ones are get-only
		mixin(MakeGetFunc!("ZMQ_TYPE", "int"));
		mixin(MakeGetFunc!("ZMQ_RCVMORE", "long"));
		mixin(MakeGetFunc!("ZMQ_FD", "socket_t"));
		mixin(MakeGetFunc!("ZMQ_EVENTS", "uint"));
	}
	int bind(string endpoint) {
		return zmq_bind(_socket, endpoint.toStringz());
	}
	int connect(string endpoint) {
		return zmq_connect(_socket, endpoint.toStringz());
	}
	alias _socket this;
}

class Message
{
private:
    // The underlying message
    zmq_msg_t msg;
public:

    this() {
        int rc = zmq_msg_init(&msg);
        if (rc != 0) throw new ZMQError();
    }

    this(size_t size_) {
        int rc = zmq_msg_init_size(&msg, size_);
        if (rc != 0) throw new ZMQError();
    }

    this(void *data_, size_t size_, zmq_free_fn ffn_, void *hint_ = null) {
        int rc = zmq_msg_init_data(&msg, data_, size_, ffn_, hint_);
        if (rc != 0) throw new ZMQError();
    }

    ~this() {
        int rc = zmq_msg_close(&msg);
        assert(rc == 0);
    }

    void rebuild () {
        int rc = zmq_msg_close(&msg);
        if (rc != 0) throw new ZMQError();
        rc = zmq_msg_init(&msg);
        if (rc != 0) throw new ZMQError();
    }

    void rebuild (size_t size_) {
        int rc = zmq_msg_close(&msg);
        if (rc != 0) throw new ZMQError();
        rc = zmq_msg_init_size(&msg, size_);
        if (rc != 0) throw new ZMQError();
    }

    void rebuild (void *data_, size_t size_, zmq_free_fn ffn_, void *hint_ = null) {
        int rc = zmq_msg_close(&msg);
        if (rc != 0) throw new ZMQError();
        rc = zmq_msg_init_data(&msg, data_, size_, ffn_, hint_);
        if (rc != 0) throw new ZMQError ();
    }

    void move (Message *msg_) {
        int rc = zmq_msg_move(&msg, &(msg_.msg));
        if (rc != 0) throw new ZMQError();
    }

    void copy (Message *msg_) {
        int rc = zmq_msg_copy(&msg, &(msg_.msg));
        if (rc != 0) throw new ZMQError();
    }

    void *data () {
        return zmq_msg_data (&msg);
    }

    size_t size () {
        return zmq_msg_size (&msg);
    }

};

int poll(zmq_pollitem_t *items, int nitems, long timeout) {
	return zmq_poll(items, nitems, timeout);
}

class ZMQError : Error {
public:
    this () {
    	super( format("%s", zmq_strerror(zmq_errno ())), file, line );
	}
};