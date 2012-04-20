module dzmq;

import std.string : toStringz, format;
import std.array: canFind;
import std.stdio;

import zmq;

version (win32)
{
    alias SOCKET socket_t;
} else {
    alias int socket_t;
    enum EAGAIN = 11; // OH GOD JANKY
}

alias extern(C) void function(void *data, void *hint) zmq_free_fn;

// Socket options
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
    RECOVERY_IVL_MSEC = ZMQ_RECOVERY_IVL_MSEC,
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
	private {
		const longOptions = [Option.SWAP, Option.RATE, Option.RECOVERY_IVL,
			Option.RECOVERY_IVL_MSEC, Option.MCAST_LOOP, Option.SNDBUF, Option.RCVBUF, Option.RCVMORE];
		const intOptions = [Option.LINGER, Option.RECONNECT_IVL,
			Option.RECONNECT_IVL_MAX, Option.BACKLOG, Option.TYPE];
		const ulongOptions = [Option.HWM, Option.AFFINITY, Option.IDENTITY];
		const stringOptions = [Option.SUBSCRIBE, Option.UNSUBSCRIBE];
	}
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
		void subscribe(string topic) {
			auto err = zmq_setsockopt(_socket, cast(int)Option.SUBSCRIBE, cast(char*)topic.ptr, topic.length);
			if(err) {
				throw new ZMQError();
			}
		}
		void unsubscribe(string topic) {
			auto err = zmq_setsockopt(_socket, cast(int)Option.UNSUBSCRIBE, cast(char*)topic.ptr, topic.length);
			if(err) {
				throw new ZMQError();
			}
		}
		void identity(string ident) {
			auto err = zmq_setsockopt(_socket, cast(int)Option.IDENTITY, cast(char*)ident.ptr, ident.length);
			if(err) {
				throw new ZMQError();
			}
		}
		string identity() {
			char[256] data;
			ulong len = 0;
			auto err = zmq_getsockopt(_socket, cast(int)Option.IDENTITY, data.ptr, &len);
			if(err) {
				throw new ZMQError();
			}
			//string ret = "";
			//foreach(i;0..len) ret ~= data[i];
			string ret = data[0..len].idup;
			return ret;
		}
	}
	
	T opt(Option option, T)()
	in {
		static if(intOptions.canFind(option)) {
			static assert(is(T == int));
		} else static if(longOptions.canFind(option)) {
			static assert(is(T == long));
		} else static if(ulongOptions.canFind(option)) {
			static assert(is(T == ulong));
		} else if(stringOptions.canFind(option)) {
			static assert(is(T == int));
		} else static if(option == Option.FD) {
			static assert(is(T == socket_t));
		} else {
			static assert(0);
		}
	} body {
		size_t len;
		T ret;
		auto err = zmq_getsockopt(_socket, option, &ret, &len);
		if(err) {
			// err is somehow not 0
			throw new ZMQError();
		} else {
			assert(len==ret.sizeof);
			return ret;
		}
	}
	
	void opt(Option option, T)(T newval) 
	in {
		static if(intOptions.canFind(option)) {
			static assert(is(T == int));
		} else static if(longOptions.canFind(option)) {
			static assert(is(T == long));
		} else static if(ulongOptions.canFind(option)) {
			static assert(is(T == ulong));
		} else static if(stringOptions.canFind(option)) {
			static assert(is(T == int));
		} else static if(option == Option.FD) {
			static assert(is(T == socket_t));
		} else {
			static assert(0);
		}
	} body {
		auto err = zmq_setsockopt(_socket, cast(int)option, cast(void*)&newval, T.sizeof);
		if(err) {
			throw new ZMQError();
		}
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
    	char* errmsg = zmq_strerror(zmq_errno ());
    	string msg = "";
    	char* tmp = errmsg;
    	while(*tmp) {
    		msg ~= *(tmp++);
    	}
    	super( format("%s", msg/+, file, line +/));
	}
};
