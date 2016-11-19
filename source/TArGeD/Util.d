/**
*	Utility functions
*/
module TArGeD.Util;

import std.stdio : File;
import std.bitmanip : littleEndianToNative, nativeToLittleEndian;
import std.algorithm : min;
import std.traits : isIntegral;
import TArGeD.Defines;

T readValue(T)(ref ubyte* c, ubyte* s, ubyte* e)
in {
	assert(c + T.sizeof <= e, "End of stream reached");
} body {
	ubyte[T.sizeof] buffer = c[0..T.sizeof];
	c += T.sizeof;
	return littleEndianToNative!T(buffer);
}

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

void writeToFile(T)(ref File f, T data)
if(isIntegral!T) {
	ubyte[T.sizeof] buffer = nativeToLittleEndian!T(data);
	f.rawWrite(buffer);
}

ubyte[] writeToArray(T)(ref File f, T data, size_t size) {
	const auto k = min(T.sizeof, size);
	return nativeToLittleEndian!T(data)[0..k].dup;
}
