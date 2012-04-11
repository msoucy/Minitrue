/+
	Minitrue
	System for CSH's BigBrother
	msoucy@csh.rit.edu
+/
module Minitrue;

private import bigbrother;

import std.stdio;

void main(string[] argv) {
	static if(0) {
		assert(argv.length == 2);
		switch(argv[1]) {
			case "hub", "h":
				break;
			case "pub", "p":
				break;
			case "sub", "s":
				break;
			default:
				break;
		}
	} else {
		
	}
	return;
}