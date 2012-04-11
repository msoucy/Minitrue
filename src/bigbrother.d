module bigbrother;

import std.array;
import std.json;
import std.stdio;
import std.string;

import dzmq;

class MessagingHub {
	private {
		// Private storage for various data
		Context context;
		string hub_name, worker_url;
		uint pub_port, sub_port, max_workers;
		dzmq.Socket subscriber_sock;
		dzmq.Socket publisher_sock;
		dzmq.Socket worker_sock;
		string[] peers = [];
	}
    /*
    Central Messaging hub used to direct traffic and send messages from publishers to all subscribers

    :type hub_name: str
    :param hub_name: name of the hub, used in routing traffic

    :type pub_port: int
    :param pub_port: port to listen for incoming publishers on

    :type sub_port: int
    :param sub_port: port to listen for outgoing subscribers on

    :type max_workers: int
    :param max_workers: max number of threads to use to process incoming messages

    :type peers: list
    :param peers: list of peer hubs to connect to and get data from
    */
    this(string hub_name, uint pub_port, uint sub_port, uint max_workers=10, string[] peers=[]) {
        this.hub_name = hub_name;
        this.pub_port = pub_port;
        this.sub_port = sub_port;
        this.context = new dzmq.Context(1);
        this.subscriber_sock = new dzmq.Socket(this.context, Socket.Type.PUB);
        this.publisher_sock = new dzmq.Socket(this.context, Socket.Type.DEALER);
        this.worker_sock = new dzmq.Socket(this.context, Socket.Type.DEALER);
        this.max_workers = max_workers;
        this.worker_url = "inproc://workers";
        //peers list is just a list of "tcp://hub_addr:hub_port" we then connect to this and use it to subscribe to their shits
        this.peers = peers;
    }

    /*
    Worker used to forward messaging coming from publishers to the subscribers
    */
    void worker() {
        auto worker_sock = new dzmq.Socket(this.context, Socket.Type.REP);
        worker_sock.connect(worker_url);
        while(1) {
            auto msg = worker_sock.recv();
            auto split_msg = msg.split("::");
            auto routing = split_msg[0];
            if(-1 != routing.indexOf("{")) {
                this.subscriber_sock.send(this.hub_name ~ "::" ~ msg);
            }
            if(-1 != routing.indexOf(this.hub_name)) {
                this.subscriber_sock.send(this.hub_name ~ ":" ~ msg);
            }
            worker_sock.send("");
        }
    }

    /*
    Start the messaging hub
    */
    void start() {
        this.worker_sock.bind(this.worker_url);
        this.subscriber_sock.bind("tcp://*:%d".format(this.sub_port));
        this.publisher_sock.bind("tcp://*:%d".format(this.pub_port));
        /*
        foreach(peer; this.peers) {
            auto processDevice = ProcessDevice(Socket.Type.QUEUE, Socket.Type.SUB, Socket.Type.REQ);
            processDevice.connect_out(peer);
            processDevice.connect_in("tcp://localhost:{}".format(this.pub_port));
            processDevice.start();
        }

        foreach(i;0..(this.max_workers)) {
            t = Thread(target=this.worker);
            t.start();
        }
        zmq.device(Socket.Type.QUEUE,this.publisher_sock,this.worker_sock);
        */
    }
}

/**
Recive messages being distributed by the hub we connect to
*/
class MessagingSubscriber {
	private {
		// Private storage for various data
		dzmq.Context context;
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
    	this.context = new dzmq.Context(1);
        this.subscription = new dzmq.Socket(this.context, Socket.Type.SUB);
        foreach(string sub;subscriptions) {
            this.subscription.opt!(Option.SUBSCRIBE) = sub;
        }
        this.addr = hub_addr;
        this.port = hub_port;
    }

    void start() {
        this.subscription.connect("tcp://{}:{}".format(this.addr,this.port));
        while(1) {
            auto data = this.subscription.recv();
            auto i=data.indexOf("::");
            data = data[(i!=-1?i:0)..$]; //throw out the routing information we do not need it here
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
		dzmq.Context context;
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
		this.context = new dzmq.Context(1);
		this.publisher = new dzmq.Socket(this.context, Socket.Type.PUB);
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