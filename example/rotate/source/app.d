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
	Pixel[][] o = new Pixel[][](i.Height, i.Width);
	Pixel[] cpy;
	switch(args[3]) {
		case "180":
			reverse(i.Pixels);	// Just reverse all pixel data
			i.write(args[2]);
			break;
		case "90":
			for(size_t w = 0; w < i.Width; w++)
				for(size_t h = 0; h < i.Height; h++)
					o[h][w] = i.Pixels(w, h);

			foreach(ref k; o)
				cpy ~= k;
			i.Pixels = cpy;
			reverse(i.Pixels);
			i.write(args[2]);
			break;
		case "-90":
			for(size_t w = 0; w < i.Width; w++)
				for(size_t h = 0; h < i.Height; h++)
					o[h][w] = i.Pixels(w, h);

			foreach(ref k; o)
				cpy ~= k;
			i.Pixels = cpy;
			i.write(args[2]);
			break;
		default:
			writeln("Wrong angle");
			break;
	}
}

