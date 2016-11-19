/**
*	Utility functions
*/
module TArGeD.Util;

import std.bitmanip : littleEndianToNative;
import std.conv : to;
import std.traits : isArray;
import TArGeD.Defines;

T readValue(T)(ref ubyte* c, ubyte* s, ubyte* e)
in {
	assert(c + T.sizeof <= e, "End of stream reached");
	assert(c >= s, "Wrong pointer");
} body {
	ubyte[T.sizeof] buffer = c[0..T.sizeof];
	c += T.sizeof;
	return littleEndianToNative!T(buffer);
}

T readArray(T)(ref ubyte* c, ubyte* s, ubyte* e) if(isArray!T)
in {
	assert(c + T.length - 1 <= e, "End of stream reached");
	assert(c >= s, "Wrong pointer");
} body {
	T o;
	for(size_t i = 0; i < o.length; i++)
		o[i] = c[i].to!(typeof(o[i]));
	c += o.length;
	return o;
}
