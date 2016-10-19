import std.stdio;
import std.algorithm;
import std.range;
import TArGeD;

void main(string[] args) {
	if(args.length != 4) {
		writefln("Usage: %s <input> <output> <-90|180|90>", args[0]);
		return;
	}

	auto i = new Image(args[1]);
	switch(args[3]) {
		case "180":
			reverse(i.Pixels);	// Just reverse all pixel data
			i.write(args[2]);
			break;
		case "90":
			break;
		case "-90":
			break;
		default:
			writeln("Wrong angle");
			break;
	}
}

