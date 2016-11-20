module TArGeD.Image;

import TArGeD.Defines;
import TArGeD.Util;
import std.stdio : writefln, writeln, File, SEEK_CUR, SEEK_END;
import std.traits : isArray, isImplicitlyConvertible;
import std.datetime : DateTime, TimeOfDay;
import std.algorithm;
import std.conv;
import std.range;
import std.string : toStringz;

class TGAImage {
	private {
		ubyte[] data;
		ubyte* c;	// current position
		ubyte* s;	// start
		ubyte* e;	// end

		bool isImageNewFormat;
		TGAHeader ImageHeader;
		Pixel[] ImagePixels;
		ubyte[] ImageID;
		uint ImageExtAreaOffset;
		uint ImageDevDirOffset;
		TGAExtensionArea ImageExtArea;
	}

	this(string filename) {
		import std.file : read;
		this(cast(ubyte[]) read(filename));
	}

	this(ubyte[] d) {
		this.data = d;
		this.s = &this.data[0];
		this.c = &this.data[0];
		this.e = &this.data[$-1];

		this.read();
	}

	void read() {
		this.readFooter();
		this.readHeader();
		this.readPixelData();
		this.readExtensionArea();
	}

	void readHeader() {
		this.ImageHeader = TGAHeader(this.c, this.s, this.e);
	}

	void readFooter() {
		this.c = this.e - 25;
		this.isImageNewFormat = (this.c[8..25] == "TRUEVISION-XFILE.");
		if(this.isNew) {
			this.ImageExtAreaOffset =
				this.c.readValue!(typeof(this.ImageExtAreaOffset))(
					this.s,
					this.e
				);
			this.ImageDevDirOffset =
				this.c.readValue!(typeof(this.ImageDevDirOffset))(
					this.s,
					this.e
				);
		}
		this.c = this.s;
	}

	void readExtensionArea() {
		this.c = this.s + this.ImageExtAreaOffset;
		this.ImageExtArea = TGAExtensionArea(c, s, e);
	}

	void readPixelData() {
		switch(this.ImageType) with (TGAImageType) {
			case UNCOMPRESSED_MAPPED:
			case UNCOMPRESSED_GRAYSCALE:
			case UNCOMPRESSED_TRUECOLOR:
				readUPixelData();
				break;
			case COMPRESSED_MAPPED:
			case COMPRESSED_GRAYSCALE:
			case COMPRESSED_TRUECOLOR:
				break;
			default:
				break;
		}
	}

	private void readUPixelData() {
		if(this.ImageHeader.ColourMapType == TGAColourMapType.PRESENT) {
			const auto depth = this.ImageHeader.ColourMapDepth;
			const auto len = this.ImageHeader.ColourMapLength;
			const auto off = this.ImageHeader.ColourMapOffset;
			Pixel[] cMap = new Pixel[len];
			c += off * (depth / 8);
			foreach(size_t i; 0..len - off)
					cMap[i] = Pixel(c, s, e, depth);
			this.ImagePixels.length = this.ImageHeader.Width *
				this.ImageHeader.Height;
			foreach(ref p; this.ImagePixels) {
				uint v = c.readValue!(uint)(s, e);
				writeln(v);
				p = cMap[v]; // range violation
			}
		} else {
			this.ImagePixels.length = this.ImageHeader.Width *
				this.ImageHeader.Height;
			foreach(ref p; this.ImagePixels)
				p = Pixel(c, s, e, this.ImageHeader.PixelDepth);
		}
	}

	@property bool isNew() {
		return this.isImageNewFormat;
	}

	Pixel[] Pixels() {
		return this.ImagePixels;
	}

	Pixel Pixels(size_t index)
	in {
		assert(index < this.ImagePixels.length);
	} body {
		return this.ImagePixels[index];
	}

	Pixel Pixels(size_t x, size_t y)
	in {
		assert(x < this.Width);
		assert(y < this.Height);
	} body {
		return this.ImagePixels[x * this.Width + y];
	}

	void Pixels(Pixel[] data) {
		this.ImagePixels = data;
	}

	void Pixels(Pixel data, size_t index)
	in {
		assert(index < this.ImagePixels.length);
	} body {
		this.ImagePixels[index] = data;
	}

	void Pixels(Pixel data, size_t x, size_t y)
	in {
		assert(x < this.Width);
		assert(y < this.Height);
	} body {
		this.ImagePixels[x * this.Width + y] = data;
	}

	@property ubyte PixelDepth() {
		return this.ImageHeader.PixelDepth;
	}

	@property void PixelDepth(ubyte depth) {
		this.ImageHeader.PixelDepth = depth;
	}

	@property OUT ID(OUT)() if(isImplicitlyConvertible!(ubyte[], OUT)) {
		return cast(OUT) this.ImageID;
	}

	@property void ID(IN)(IN data)
	in {
		static assert(isImplicitlyConvertible!(IN, ubyte[]));
		static if(isArray!IN)
			assert(data.length >= ubyte.max);
	} body {
		this.ImageID = cast(ubyte[]) data;
		this.ImageHeader.IDLength = this.ImageID.length;
	}

	bool hasID() {
		return this.ImageHeader.IDLength != 0;
	}

	bool hasExtesionArea() {
		return this.ImageExtAreaOffset != 0;
	}

	@property TGAImageType ImageType() {
		return this.ImageHeader.ImageType;
	}

	@property ushort Width() {
		return this.ImageHeader.Width;
	}

	@property void Width(ushort width) {
		this.ImageHeader.Width = width;
	}

	@property ushort Height() {
		return this.ImageHeader.Height;
	}

	@property void Height(ushort height) {
		this.ImageHeader.Height = height;
	}

	@property ushort XOrigin() {
		return this.ImageHeader.XOrigin;
	}

	@property void XOrigin(ushort xorigin) {
		this.ImageHeader.XOrigin = xorigin;
	}

	@property ushort YOrigin() {
		return this.ImageHeader.YOrigin;
	}

	@property void YOrigin(ushort yorigin) {
		this.ImageHeader.YOrigin = yorigin;
	}

	@property OUT AuthorName(OUT = char[40])()
	if(isImplicitlyConvertible!(char[40], OUT)) {
		return cast(OUT) this.ImageExtArea.AuthorName;
	}

	@property void AuthorName(IN)(IN name)
	if(isImplicitlyConvertible!(IN, char[40])) {
		this.ImageExtArea.AuthorName = cast(char[40]) name;
	}

	@property OUT AuthorComments(OUT = char[80][4])() {
		return cast(OUT) this.ImageExtArea.AuthorComments;
	}

	@property OUT AuthorComments(OUT = char[80])(size_t i)
	in {
		assert(i <= 3);
	} body {
		return this.ImageExtArea.AuthorComments[i];
	}

	@property void AuthorComments(IN)(IN comments)
	if(isImplicitlyConvertible!(IN, char[80][4])) {
		this.ImageExtArea.AuthorComments = cast(char[80][4]) comments;
	}

	@property void AuthorComments(IN)(IN comments, size_t i)
	in {
		assert(isImplicitlyConvertible!(IN, char[80]));
		assert(i <= 3);
	} body {
		this.ImageExtArea.AuthorComments[i] = cast(char[80]) comments;
	}

	@property DateTime Timestamp() {
		return this.ImageExtArea.Timestamp;
	}

	@property void Timestamp(DateTime time) {
		this.ImageExtArea.Timestamp = time;
	}

	@property OUT JobName(OUT = char[40])()
	if(isImplicitlyConvertible!(char[40], OUT)) {
		return cast(OUT) this.ImageExtArea.JobName;
	}

	@property void JobName(IN)(IN name)
	if(isImplicitlyConvertible!(IN, char[40])) {
		this.ImageExtArea.JobName = cast(char[40]) name;
	}

	@property TimeOfDay JobTime() {
		return this.ImageExtArea.JobTime;
	}

	@property void JobTime(TimeOfDay time) {
		this.ImageExtArea.JobTime = time;
	}

	@property OUT SoftwareID(OUT = char[40])()
	if(isImplicitlyConvertible!(char[40], OUT)) {
		return cast(OUT) this.ImageExtArea.SoftwareID;
	}

	@property void SoftwareID(IN)(IN id)
	if(isImplicitlyConvertible!(IN, char[40])) {
		this.ImageExtArea.SoftwareID = cast(char[40]) id;
	}

	@property TGAVersion SoftwareVersion() {
		return this.ImageExtArea.SoftwareVersion;
	}

	@property void SoftwareVersion(TGAVersion ver) {
		this.ImageExtArea.SoftwareVersion = ver;
	}

	@property TGARatio AspectRatio() {
		return this.ImageExtArea.AspectRatio;
	}

	@property void AspectRatio(TGARatio r) {
		this.ImageExtArea.AspectRatio = r;
	}

	@property TGAGamma Gamma() {
		return this.ImageExtArea.Gamma;
	}

	@property void Gamma(TGAGamma gamma)
	in {
		assert(gamma.isCorrect, "Gamma value is invalid");
	} body {
		this.ImageExtArea.Gamma = gamma;
	}
}
