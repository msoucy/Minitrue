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

private template MakeOptFunc(string name, string type) {
	const char[] MakeOptFunc = type~` opt_in(Option N:Option.`~name~`)(Variant newval) {
	assert(newval.peek!(`~type~`)() !is null);
	this._in_sockopts ~= SockOpt(N, newval.get!(`~type~`)());
	return newval.get!(`~type~`)();
}` ~ "\n" ~ type~` opt_out(Option N:Option.`~name~`)(Variant newval) {
	assert(newval.peek!(`~type~`)() !is null);
	this._out_sockopts ~= SockOpt(N, newval.get!(`~type~`)());
	return newval.get!(`~type~`)();
}`;
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
	
	void opt_in(dzmq.Option option, Variant newval) {
		this._in_sockopts ~= SockOpt(option, newval);
	}
	
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
        // Fill in the options
        foreach(opt;this._in_sockopts) {
			/+
			switch(opt.option) {
				case Option.HWM: {
					assert(opt.value.peek!(string)() !is null);
		        	/*ins.opt!Option.HWM = */opt.value.get!string();
					break;
				}
			}
			+/
        }
	}
	
}
