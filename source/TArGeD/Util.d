/**
*	Utility functions
*/
module TArGeD.Util;

import std.bitmanip : littleEndianToNative;
import std.conv : to;
import std.traits : isArray;
import std.algorithm : min;
import TArGeD.Defines;

T readValue(T)(ref ubyte* c, ubyte* s, ubyte* e)
in {
	assert(c + T.sizeof <= e, "End of image reached");
	assert(c >= s, "Wrong pointer");
} body {
	ubyte[T.sizeof] buffer = c[0..T.sizeof];
	c += T.sizeof;
	return littleEndianToNative!T(buffer);
}

T readValue(T)(ref ubyte* c, ubyte* s, ubyte* e, ubyte depth)
in {
	assert(c + T.sizeof <= e, "End of image reached");
	assert(c >= s, "Wrong pointer");
} body {
	const auto k = min(cast(uint) T.sizeof, depth / 8);
	ubyte[T.sizeof] buffer;
	buffer[0..k] = c[0..k];
	c += k;
	return littleEndianToNative!T(buffer);
}

T[] readArray(T)(ref ubyte* c, ubyte* s, ubyte* e, size_t len)
in {
	assert(c + (T.sizeof * len) - 1 <= e, "End of image reached");
	assert(c >= s, "Wrong pointer");
} body {
	T[] o;
	for(size_t i = 0; i < o.length; i++)
		o[i] = c[i].to!(T);
	c += len;
	return o;
}

T readArray(T)(ref ubyte* c, ubyte* s, ubyte* e) if(isArray!T)
in {
	assert(c + T.length - 1 <= e, "End of image reached");
	assert(c >= s, "Wrong pointer");
} body {
	T o;
	for(size_t i = 0; i < o.length; i++)
		o[i] = c[i].to!(typeof(o[i]));
	c += o.length;
	return o;
}
