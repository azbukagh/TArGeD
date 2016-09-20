module TArGeD.Util;

import std.stdio : File;
import std.bitmanip : littleEndianToNative;
import std.algorithm : min;

T readFile(T)(ref File f) {
	ubyte[T.sizeof] buffer;
	f.rawRead(buffer);
	return littleEndianToNative!T(buffer);
}

T readArray(T)(ubyte[] data) {
	const auto k = min(cast(uint) T.sizeof, data.length);
	ubyte[T.sizeof] o;
	o[0..k] = data[0..k];
	return littleEndianToNative!T(o);
}

