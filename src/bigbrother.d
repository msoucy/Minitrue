module bigbrother;

private import dzmq;

static dzmq.Context context;
static this() {
	context = new Context(1);
}

class MessagingPublisher {
	private {
		string addr;
		uint port;
		int publisher;
	}
	this(string addr, uint port) {
		this.addr = addr;
		this.port = port;
		//this.publisher = context.
	}
}