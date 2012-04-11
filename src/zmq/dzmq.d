module dzmq;

import std.string : toStringz, format;

import zmq;

version (win32)
{
    alias SOCKET socket_t;
} else {
    alias int socket_t;
    enum EAGAIN = 11; // OH GOD JANKY
}

alias extern(C) void function(void *data, void *hint) zmq_free_fn;

private template MakeSetFunc(string name, string type) {
	const char[] MakeSetFunc = type~` opt(Option N:Option.`~name~`)(`~name~` newval) {
	pragma(msg, "`~type~`");
	auto err = zmq_setsockopt(_socket, N, &newval, `~type~`.sizeof);
	if(err) {
		throw new ZMQError();
	} else {
		return newval;
	}
}`;
}
private template MakeSetFunc(string name, string type : "string") {
	const char[] MakeSetFunc = type~` opt(Option N:Option.`~name~`)(`~name~` newval) {
	auto err = zmq_setsockopt(_socket, N, newval.ptr, newval.length);
	if(err) {
		throw new ZMQError();
	} else {
		return newval;
	}
}`;
}
private template MakeGetFunc(string name, string type) {
	const char[] MakeGetFunc = type~` opt(Option N:Option.`~name~`)() {
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
	const char[] MakeFuncs = MakeGetFunc!(name,type)~"\n"~MakeSetFunc!(name,type);
}

/*  Socket options.                                                           */
immutable enum Option
{
    HWM             = ZMQ_HWM,
    SWAP            = ZMQ_SWAP,
    AFFINITY        = ZMQ_AFFINITY,
    IDENTITY        = ZMQ_IDENTITY,
    SUBSCRIBE       = ZMQ_SUBSCRIBE,
    UNSUBSCRIBE     = ZMQ_UNSUBSCRIBE,
    RATE            = ZMQ_RATE,
    RECOVERY_IVL    = ZMQ_RECOVERY_IVL,
    MCAST_LOOP      = ZMQ_MCAST_LOOP,
    SNDBUF          = ZMQ_SNDBUF,
    RCVBUF          = ZMQ_RCVBUF,
    RCVMORE         = ZMQ_RCVMORE,
    FD              = ZMQ_FD,
    EVENTS          = ZMQ_EVENTS,
    TYPE            = ZMQ_TYPE,
    LINGER          = ZMQ_LINGER,
    RECONNECT_IVL   = ZMQ_RECONNECT_IVL,
    BACKLOG         = ZMQ_BACKLOG,
    RECOVERY_IVL_MSEC = ZMQ_RECOVERY_IVL_MSEC, /*opt. recovery time, reconcile in 3.x */
    RECONNECT_IVL_MAX = ZMQ_RECONNECT_IVL_MAX
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
	public immutable enum Type {
		PAIR        = ZMQ_PAIR,
	    PUB         = ZMQ_PUB,
	    SUB         = ZMQ_SUB,
	    REQ         = ZMQ_REQ,
	    REP         = ZMQ_REP,
	    DEALER      = ZMQ_DEALER,
	    ROUTER      = ZMQ_ROUTER,
	    PULL        = ZMQ_PULL,
	    PUSH        = ZMQ_PUSH,
	    XPUB        = ZMQ_XPUB,
	    XSUB        = ZMQ_XSUB,
	}
	public immutable enum Flags {
		NOBLOCK = ZMQ_NOBLOCK,
		SNDMORE = ZMQ_SNDMORE,
	}
	
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
		mixin(MakeFuncs!("HWM", "ulong"));
		mixin(MakeFuncs!("SWAP", "long"));
		mixin(MakeFuncs!("AFFINITY", "ulong"));
		mixin(MakeFuncs!("IDENTITY", "ulong"));
		// These two don't have matching constants
		//mixin(MakeFuncs!("RCVTIMEO", "int"));
		//mixin(MakeFuncs!("SNDTIMEO", "int"));
		mixin(MakeFuncs!("RATE", "long"));
		mixin(MakeFuncs!("RECOVERY_IVL", "long"));
		mixin(MakeFuncs!("RECOVERY_IVL_MSEC", "long"));
		mixin(MakeFuncs!("MCAST_LOOP", "long"));
		mixin(MakeFuncs!("SNDBUF", "long"));
		mixin(MakeFuncs!("RCVBUF", "long"));
		mixin(MakeFuncs!("LINGER", "int"));
		mixin(MakeFuncs!("RECONNECT_IVL", "int"));
		mixin(MakeFuncs!("RECONNECT_IVL_MAX", "int"));
		mixin(MakeFuncs!("BACKLOG", "int"));
		
		// These ones are set-only
		mixin(MakeSetFunc!("SUBSCRIBE", "string"));
		mixin(MakeSetFunc!("UNSUBSCRIBE", "string"));
		
		// These ones are get-only
		mixin(MakeGetFunc!("TYPE", "int"));
		mixin(MakeGetFunc!("RCVMORE", "long"));
		mixin(MakeGetFunc!("FD", "socket_t"));
		mixin(MakeGetFunc!("EVENTS", "uint"));
	}
	int bind(string endpoint) {
		return zmq_bind(_socket, endpoint.toStringz());
	}
	int connect(string endpoint) {
		return zmq_connect(_socket, endpoint.toStringz());
	}
	int send(string msg, int flags=0) {
		Message m = new Message(cast(void*)msg.ptr, msg.length, null, null);
		int nbytes = zmq_send (_socket, m.getmsg, flags);
        if (nbytes >= 0) return nbytes;
        else if (zmq_errno () == EAGAIN) return 0;
        else throw new ZMQError();
	}
	int send(Message msg, int flags=0) {
		int nbytes = zmq_send (_socket, msg.getmsg(), flags);
        if (nbytes >= 0) return nbytes;
        else if (zmq_errno () == EAGAIN) return 0;
        else throw new ZMQError();
	}
	string recv(int flags=0) {
		Message m = new Message();
		int nbytes = this.recv(m, flags);
		string ret;
		for(int i=0;i<m.size;i++) {
			ret ~= (cast(char*)m.data)[i];
		}
		return ret;
	}
	int recv(Message msg, int flags=0) {
		int nbytes = zmq_recv (_socket, msg.getmsg(), flags);
        if (nbytes >= 0) return nbytes;
        else if (zmq_errno () == EAGAIN) return 0;
        else throw new ZMQError();
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
    
    zmq_msg_t* getmsg() {
    	return &msg;
    }
    
    alias msg this;
    
};

int poll(zmq_pollitem_t *items, int nitems, long timeout) {
	auto rc = zmq_poll(items, nitems, timeout);
	if (rc == -1) throw new ZMQError();
	return rc;
}

class ZMQError : Error {
public:
    this () {
    	super( format("%s", zmq_strerror(zmq_errno ())), file, line );
	}
};
