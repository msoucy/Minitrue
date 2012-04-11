module bigbrother;

import std.array;
import std.stdio;
import std.json;

private import dzmq;

static dzmq.Context context;
static this() {
	context = new dzmq.Context(1);
}

/**
Recive messages being distributed by the hub we connect to
*/
class MessagingSubscriber {
	private {
		// Private storage for various data
		string addr;
		uint port;
		dzmq.Socket subscription;
	}
    /**
    Create a new subscriber and subscribe it to 1 or more topics being
    broadcasted by the selected hub

    :type hub_addr: str
    :param hub_addr: address of the hub we want to connect to

    :type hub_port: int
    :param hub_port: port of the hub we want to connect to

    :type subscriptions: list
    :param subscriptions: list of topics to subscribe to
    */
    this(string hub_addr, int hub_port, string[] subscriptions=[""]) {
        this.subscription = new dzmq.Socket(context, Socket.Type.SUB);
        foreach(string sub;subscriptions) {
        	long l;
            this.subscription.opt!Option.RATE(l);
        }
        this.addr = hub_addr;
        this.port = hub_port;
    }

    void start() {
        this.subscription.connect("tcp://{}:{}".format(this.addr,this.port));
        while(1) {
            auto data = this.subscription.recv();
            data = data.split("::");
            data = "::".join(data[1..$]); //throw out the routing information we do not need it here
            /*t = Thread(target=self.process, args=(json.loads(data),));
            t.start()*/
        }
    }

    /**
    Easily over-rideable function used to process the recieved data

    :type data: dict
    :param data: a dict containing the json object revieved from the hub
    */
    void process(JSONValue data) {
        writef("%s", data);
    }
}

class MessagingPublisher {
	private {
		// Private storage for various data
		string addr;
		uint port;
		dzmq.Socket publisher;
	}
	/**
	Create a new MessagingPublisher and connect it to a specified hub
    :type hub_addr: str
    :param hub_addr: Address of the messaging hub

    :type hub_port: int
    :param hub_port: port of the messaging hub
	*/
	this(string addr, uint port) {
		this.addr = addr;
		this.port = port;
		this.publisher = new dzmq.Socket(context, Socket.Type.PUB);
		this.publisher.connect(format("tcp://%s:%s",addr,port));
	}
	/**
	Publish a mesage to the network

    :type topic: string
    :param topic: the messages topic (helps subscribes decide if they want to recieve this message

    :type kwargs: dict
    :param kwargs: used to create a json blob which is the message to be sent
	*/
	void publish(string topic, string data) {
		writef("Sending<%s>:\t%s\n",topic, data);
		this.publisher.send("minitrue", Socket.Flags.SNDMORE);
	}
}