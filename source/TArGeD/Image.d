module TArGeD.Image;

import TArGeD.Defines;
import TArGeD.Util;
import std.stdio : writeln, File, SEEK_CUR, SEEK_END;
import std.traits : isArray, isImplicitlyConvertible;
import std.datetime : DateTime, TimeOfDay;
import std.algorithm;
import std.conv;
import std.range;
import std.string : toStringz;
import std.file;

class TGAImage {
	private {
		ubyte[] data;
		ubyte* c;
		ubyte* s;
		ubyte* e;
	}
	TGAHeader ImageHeader;

	this(string name) {
		this(cast(ubyte[]) read(name));
	}

	this(ubyte[] d) {
		this.data = d;
		this.s = &this.data[0];
		this.c = &this.data[0];
		this.e = &this.data[$-1];

		this.ImageHeader = TGAHeader(this.c, this.s, this.e);
	}
}
