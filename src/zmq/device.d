/**
	Devices for zmq
		Matthew Soucy (msoucy@csh.rit.edu)
	Derived from the pyzmq files by:
		MinRK
		Brian Granger
*/
import dzmq;

import std.concurrency;
import std.process;
import std.variant;

private struct SockOpt {
	public {
		dzmq.Option option;
		Variant value;
	}
	this(Option o, Variant v) {
		this.option = o;
		this.value = v;
	} 
}

private template MakeSetFunc(string name, string type) {
	const char[] MakeSetFunc = type~` opt(Option N:Option.`~name~`)(`~type~` newval) {
	auto err = zmq_setsockopt(_socket, N, &newval, `~type~`.sizeof);
	if(err) {
		throw new ZMQError();
	}
}`;
}
private template MakeSetFunc(string name, string type : "string") {
	const char[] MakeSetFunc = type~` opt(Option N:Option.`~name~`)(`~type~` newval) {
	auto err = zmq_setsockopt(_socket, cast(int)N, cast(void*)newval.ptr, newval.length);
	if(err) {
		throw new ZMQError();
	}
	return newval;
}`;
}
private template MakeGetFunc(string name, string type) {
	const char[] MakeGetFunc = type~` opt(Option N:Option.`~name~`)() {
	size_t len;
	`~type~` ret;
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

class Device {
	private {
		dzmq.Socket.Type device_type, in_type, out_type;
		bool daemon=true;
		bool done=false;
		string[] _in_binds=[], _in_connects=[];
		string[] _out_binds=[], _out_connects=[];
		SockOpt[] _in_sockopts=[], _out_sockopts=[];
	}
	this(dzmq.Socket.Type device_type, dzmq.Socket.Type in_type, dzmq.Socket.Type out_type) {
		this.device_type = device_type;
        this.in_type = in_type;
        this.out_type = out_type;
        this._in_binds = [];
        this._in_connects = [];
        this._in_sockopts = [];
        this._out_binds = [];
        this._out_connects = [];
        this._out_sockopts = [];
	}
	
	void bind_in(string addr) {_in_binds ~= addr;}
	void bind_out(string addr) {_out_binds ~= addr;}
	void connect_in(string addr) {_in_connects ~= addr;}
	void connect_out(string addr) {_out_connects ~= addr;}
	
	//void setsockopt_in(string addr) {_in_sockopts ~= addr;}
	//void setsockopt_out(string addr) {_out_sockopts ~= addr;}
	//mixin(dzmq.SockOptFuncs!);
	
	private void setup_sockets(out Socket ins, out Socket outs) {
		Context ctx = new Context(1);
		// Create sockets
		ins = new Socket(ctx, this.in_type);
		outs = null;
        if(this.out_type < 0) {
            outs = ins;
        } else {
            outs = new Socket(ctx, this.out_type);
        }
	}
	
}
