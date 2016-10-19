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

class Image {
	private {
		TGAHeader ImageHeader;
		ubyte[] ImageID;
		Pixel[] ImageColourMap;
		Pixel[] ImagePixels;
		uint ImageExtAreaOffset;
		uint ImageDevDirOffset;
		TGAExtensionArea ImageExtArea;

		bool isImageNewFormat;
	}

	void write(string filename) {
		this.write(File(filename, "wb"));
	}

	void write(File f) {
		if(this.isColourMapped) {
			this.ImageHeader.ColourMapOffset = TGAHeader.sizeof +
				this.ImageHeader.IDLength;
		} else {
			with(this.ImageHeader) {
				ColourMapLength = 0;
				ColourMapOffset = 0;
				ColourMapDepth = 0;
			}
		}
		this.ImageHeader.write(f);
		if(this.hasID)
			this.writeID(f);
		if(this.isColourMapped)
			this.writeColourMap(f);
		this.writePixelData(f);
		if(this.isNew) {
			this.ImageExtAreaOffset = this.ImageExtArea.write(f);
			this.writeFooter(f);
		}
	}

	this(string filename) {
		this(File(filename, "rb"));
	}

	this(File f) {
		this.readFooter(f);
		this.ImageHeader = TGAHeader(f);
		this.readID(f);
		this.readColourMap(f);
		this.readPixelData(f);
		if(this.isNew && (this.ImageExtAreaOffset != 0))
			this.ImageExtArea = TGAExtensionArea(f,
				this.ImageExtAreaOffset);
	}

	private void readFooter(ref File f) {
		f.seek(-26, SEEK_END);
		ubyte[26] buf;
		f.rawRead(buf);
		this.isNew = (buf[8..25] == "TRUEVISION-XFILE.");
		if(this.isNew) {
			this.ImageExtAreaOffset = readFromArray!uint(buf[0..4]);
			this.ImageDevDirOffset = readFromArray!uint(buf[4..8]);
		}
	}

	private void writeFooter(ref File f) {
		f.writeToFile(this.ImageExtAreaOffset);
		f.writeToFile(this.ImageDevDirOffset);
		f.write("TRUEVISION-XFILE.\0");
	}

	private void readID(ref File f) {
		if(this.hasID)
			this.ImageID =
				f.rawRead(new ubyte[this.ImageHeader.IDLength]);
	}

	private void writeID(ref File f)
	in {
		assert(this.hasID);
		assert(this.ImageID.length == this.ImageHeader.IDLength);
	} body {
		f.rawWrite(this.ImageID[0..this.ImageHeader.IDLength]);
	}

	private void readColourMap(ref File f) {
		if(!this.isColourMapped)
			return;

		this.ImageColourMap.length = this.ImageHeader.ColourMapLength;	// TODO allocate it with std.experimental.allocator

		f.seek(this.ImageHeader.ColourMapOffset *
			this.ImageHeader.ColourMapDepth, SEEK_CUR);

		ubyte[] buf = new ubyte[this.ImageHeader.ColourMapDepth/8];

		foreach(size_t i; 0..(this.ImageHeader.ColourMapLength - this.ImageHeader.ColourMapOffset)) {
			f.rawRead(buf);
			this.ImageColourMap[i] = Pixel(buf);
		}
	}

	private void writeColourMap(ref File f)
	in {
		assert(this.isColourMapped);
	} body {
		foreach(ref c; this.ColourMap)
			c.write(f, this.ImageHeader.ColourMapDepth / 8);
	}

	private void readPixelData(ref File f) {
		switch(this.ImageHeader.ImageType) with(TGAImageType) {
			case UNCOMPRESSED_MAPPED:
			case UNCOMPRESSED_TRUECOLOR:
			case UNCOMPRESSED_GRAYSCALE:
				readUncompressedPixelData(f);
				break;
			case COMPRESSED_MAPPED:
			case COMPRESSED_TRUECOLOR:
			case COMPRESSED_GRAYSCALE:
				readCompressedPixelData(f);
				break;
			default:
				throw new TArGeDException("Wrong image type");
		}
	}

	private void writePixelData(ref File f) {
		switch(this.ImageHeader.ImageType) with(TGAImageType) {
			case UNCOMPRESSED_MAPPED:
			case UNCOMPRESSED_TRUECOLOR:
			case UNCOMPRESSED_GRAYSCALE:
				writeUncompressedPixelData(f);
				break;
			case COMPRESSED_MAPPED:
			case COMPRESSED_TRUECOLOR:
			case COMPRESSED_GRAYSCALE:
				writeCompressedPixelData(f);
				break;
			default:
				throw new TArGeDException("Wrong image type");
		}
	}

	private void readUncompressedPixelData(ref File f) {
		auto r = (this.isColourMapped)
			? delegate (ubyte[] d) =>
				this.ImageColourMap[readFromArray!uint(d)]
			: delegate (ubyte[] d) =>
				Pixel(d);
		this.ImagePixels.length = this.ImageHeader.Width *
			this.ImageHeader.Height;	// TODO ALLOC

		ubyte[] buf = new ubyte[this.ImageHeader.PixelDepth/8];
		foreach(ref p; this.ImagePixels) {
			f.rawRead(buf);
			p = r(buf);
		}
	}

	private void writeUncompressedPixelData(ref File f) {
		auto r = (this.isColourMapped)
			? delegate (Pixel d) =>
				f.rawWrite(
					writeToArray(
						f,
						this.ImageColourMap
							.countUntil(d)
							.to!ushort,
						this.ImageHeader.PixelDepth/8
					)
				)
			: delegate (Pixel d) =>
				d.write(f, this.ImageHeader.PixelDepth);

		foreach(ref p; this.ImagePixels)
			r(p);
	}

	private void readCompressedPixelData(ref File f) {
		auto r = (this.isColourMapped)
			? delegate (ubyte[] d) =>
				this.ImageColourMap[readFromArray!uint(d)]
			: delegate (ubyte[] d) =>
				Pixel(d);
		this.ImagePixels.length = this.ImageHeader.Width *
			this.ImageHeader.Height;	// TODO ALLOC

		ubyte[] buf = new ubyte[this.ImageHeader.PixelDepth/8+1];
		size_t i;
		while(i < this.ImageHeader.Width * this.ImageHeader.Height) {
			f.rawRead(buf);
			size_t rep = buf[0] & 0x7F;
			this.ImagePixels[i] =
				r(buf[0..this.ImageHeader.PixelDepth/8]);
			i++;
			if(buf[0] & 0x80) {
				for(size_t j = 0; j < rep; j++, i++)
					this.ImagePixels[i] =
						r(buf[1..this.ImageHeader.PixelDepth/8+1]);
			} else {
				for(size_t j=0; j < rep; j++, i++) {
					f.rawRead(buf[0..this.ImageHeader.PixelDepth/8]);
					this.ImagePixels[i] =
						r(buf[0..this.ImageHeader.PixelDepth/8]);
				}
			}
		}
	}

	private void writeCompressedPixelData(ref File f) {
		auto r = (this.isColourMapped)
			? delegate (Pixel d) =>
				f.rawWrite(
					writeToArray(
						f,
						this.ImageColourMap
							.countUntil(d)
							.to!ushort,
						this.ImageHeader.PixelDepth/8
					)
				)
			: delegate (Pixel d) =>
				d.write(f, this.ImageHeader.PixelDepth);
		auto pixels = this.ImagePixels;
		while(pixels.length) {
			// Find the first occurrence of two equal pixels next to each other
			auto nextPixels = pixels.findAdjacent;

			// Everything before that point should be written as raw packets.
			// Max packet size is 128 pixels so make chunks of that size
			foreach(const ref packet; pixels[0 .. $ - nextPixels.length].chunks(128)) {
				f.write(to!ubyte(packet.length-1));
				foreach(const ref p; packet)
					r(p);
			}

			// If there are more pixels in the image, the next pixels can be RLE encoded
			if(nextPixels.length){
				// Find the point at which the pixel data changes
				pixels = nextPixels.find!"a!=b"(nextPixels[0]);

				// Everything before that point should be written as RLE packets
				foreach(const ref packet; nextPixels[0 .. $ - pixels.length].chunks(128)){
					f.write(to!ubyte(packet.length-1 | 0x80));
					r(packet[0]);
				}
			} else {
				break;
			}
		}
	}

	@property bool isNew() {
		return this.isImageNewFormat;
	}

	@property void isNew(bool val) {
		this.isImageNewFormat = val;
	}

	@property Pixel[] Pixels() {
		return this.ImagePixels;
	}

	@property Pixel Pixels(size_t index)
	in {
		assert(index < this.ImagePixels.length);
	} body {
		return this.ImagePixels[index];
	}

	@property Pixel Pixels(size_t x, size_t y)
	in {
		assert(x < this.Width);
		assert(y < this.Height);
	} body {
		return this.ImagePixels[x * this.Width + y];
	}

	@property void Pixels(Pixel[] data) {
		this.ImagePixels = data;
	}

	@property void Pixels(Pixel data, size_t index)
	in {
		assert(index < this.ImagePixels.length);
	} body {
		this.ImagePixels[index] = data;
	}

	@property Pixel Pixels(Pixel data, size_t x, size_t y)
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

	@property Pixel[] ColourMap() {
		return this.ImageColourMap;
	}

	@property void ColourMap(Pixel[] data)
	in {
		assert(data.length <= TGAHeader.ColourMapLength.max);
	} body {
		this.ImageColourMap = data;
		this.ImageHeader.ColourMapLength =
			cast(typeof(TGAHeader.ColourMapLength))
				this.ImageColourMap.length;
	}

	bool isColourMapped() {
		return this.ImageHeader.ColourMapType
			== TGAColourMapType.NOT_PRESENT
				? false
				: true;
	}

	void isColourMapped(bool v) {
		switch(this.ImageHeader.ImageType) with (TGAImageType) {
			case UNCOMPRESSED_TRUECOLOR:
			case UNCOMPRESSED_GRAYSCALE:
				this.ImageHeader.ImageType =
					TGAImageType.UNCOMPRESSED_MAPPED;
				break;
			
			case COMPRESSED_TRUECOLOR:
			case COMPRESSED_GRAYSCALE:
				this.ImageHeader.ImageType =
					TGAImageType.COMPRESSED_MAPPED;
				break;
			default:
				break;
		}
		this.ImageHeader.ColourMapType = v
			? TGAColourMapType.PRESENT
			: TGAColourMapType.NOT_PRESENT;
	}

	@property ubyte ColourMapDepth() {
		return this.ImageHeader.ColourMapDepth;
	}

	@property void ColourMapDepth(ubyte depth) {
		this.ImageHeader.ColourMapDepth = depth;
	}

	@property OUT ID(OUT)()
	if(isImplicitlyConvertible!(ubyte[], OUT)) {
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

	@property void ImageType(TGAImageType imagetype) {
		switch(imagetype) with (TGAImageType) {
			case COMPRESSED_TRUECOLOR:
			case COMPRESSED_GRAYSCALE:
			case UNCOMPRESSED_TRUECOLOR:
			case UNCOMPRESSED_GRAYSCALE:
				this.ImageHeader.ColourMapType =
					TGAColourMapType.NOT_PRESENT;
				break;
			case UNCOMPRESSED_MAPPED:
			case COMPRESSED_MAPPED:
				this.ImageHeader.ColourMapType =
					TGAColourMapType.PRESENT;
				break;
			default:
				break;
		}
		this.ImageHeader.ImageType = imagetype;
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

