import std.stdio;
import std.algorithm;
import std.range;
import TArGeD;

void main(string[] args) {
	if(args.length != 3) {
		writefln("Usage: %s <input> <output>", args[0]);
		return;
	}

	auto i = new Image(args[1]);
	foreach(pack; i.Pixels.chunks(3)) {
		foreach(p; pack)
			writef("%d, %d, %d \t",
				p.R,
				p.G,
				p.B);
		writeln;
	}
	i.write(args[2]);
}

