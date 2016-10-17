import std.stdio;
import TArGeD;

void main(string[] args) {
	if(args.length != 3) {
		writefln("Usage: %s <input> <output>", args[0]);
		return;
	}

	auto i = new Image(args[1]);
	writeln("Input image type:\t", i.ImageType);
	switch(i.ImageType) with(TGAImageType) {
		case UNCOMPRESSED_MAPPED:
		case UNCOMPRESSED_TRUECOLOR:
			i.ImageType = TGAImageType.UNCOMPRESSED_GRAYSCALE;
			i.PixelDepth = 8;
			i.write(args[2]);
			break;
		case COMPRESSED_MAPPED:
		case COMPRESSED_TRUECOLOR:
			i.ImageType = TGAImageType.COMPRESSED_GRAYSCALE;
			i.PixelDepth = 8;
			i.write(args[2]);
			break;
		case UNCOMPRESSED_GRAYSCALE:
		case COMPRESSED_GRAYSCALE:
			writeln("Input is black and white image");
			break;
		default:
			writeln("Wrong input image");
			break;
	}
}
