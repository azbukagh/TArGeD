/**
*	Utility functions
*/
module TArGeD.Util;

import std.stdio : File;
import std.bitmanip : littleEndianToNative, nativeToLittleEndian;
import std.algorithm : min;

T readFromFile(T)(ref File f) {
	ubyte[T.sizeof] buffer;
	f.rawRead(buffer);
	return littleEndianToNative!T(buffer);
}

T readFromArray(T)(ubyte[] data) {
	const auto k = min(cast(uint) T.sizeof, data.length);
	ubyte[T.sizeof] o;
	o[0..k] = data[0..k];
	return littleEndianToNative!T(o);
}

void writeToFile(T)(ref File f, T data) {
	ubyte[T.sizeof] buffer = nativeToLittleEndian!T(data);
	f.rawWrite(buffer);
}

void writeToFile(T)(ref File f, T data, ushort size) {
	const auto k = min(T.sizeof, size);
	ubyte[] buf = new ubyte[k];
	buf = nativeToLittleEndian!T(data);
	f.rawWrite(buf[0..k]);
}

