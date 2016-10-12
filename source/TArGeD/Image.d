module TArGeD.Image;

import TArGeD.Defines;
import TArGeD.Util;
import std.stdio : File, SEEK_CUR, SEEK_END;
import std.traits : isArray, isImplicitlyConvertible;
import std.datetime : DateTime, TimeOfDay;

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

	this(string filename) {
		this(File(filename, "rb"));
	}

	this(File f) {
		this.readFooter(f,
			this.ImageExtAreaOffset,
			this.ImageDevDirOffset);
		this.ImageHeader = TGAHeader(f);
		this.readID(f, this.ImageHeader.IDLength, this.ImageID);
		this.readColourMap(f,
			this.ImageHeader,
			this.ImageColourMap);
		this.readPixelData(f,
			this.ImageHeader,
			this.ImageColourMap,
			this.ImagePixels);
		if(this.isNew && (this.ImageExtAreaOffset != 0))
			this.ImageExtArea = TGAExtensionArea(f,
				this.ImageExtAreaOffset);
	}

	private void readFooter(ref File f, out uint extAreaOff, out uint devDirOff) {
		f.seek(-26, SEEK_END);
		ubyte[26] buf;
		f.rawRead(buf);
		this.isNew = (buf[8..24] == "TRUEVISION-XFILE" && buf[24] == '.');
		if(this.isNew) {
			extAreaOff = readFromArray!uint(buf[0..4]);
			devDirOff = readFromArray!uint(buf[4..8]);
		}
	}

	private void readID(ref File f, ubyte idLen, out ubyte[] ImgID) {
		if(idLen) {
			ImgID = f.rawRead(new ubyte[idLen]);
		}
	}

	private void readColourMap(ref File f, ref TGAHeader hdr, out Pixel[] CMap) {
			if(hdr.ColourMapType == TGAColourMapType.NOT_PRESENT) {
				return;
			}

			CMap.length = hdr.ColourMapLength;	// TODO allocate it with std.experimental.allocator

			f.seek(hdr.ColourMapOffset * hdr.ColourMapDepth, SEEK_CUR);

			ubyte[] buf = new ubyte[hdr.ColourMapDepth/8];

			foreach(size_t i; 0..(hdr.ColourMapLength - hdr.ColourMapOffset)) {
				f.rawRead(buf);
				CMap[i] = Pixel(buf);
			}
	}

	private void readPixelData(ref File f,
		ref TGAHeader hdr,
		ref Pixel[] colourMap,
		out Pixel[] pixels) {
			switch(hdr.ImageType) with(TGAImageType) {
				case UNCOMPRESSED_MAPPED:
				case UNCOMPRESSED_TRUECOLOR:
				case UNCOMPRESSED_GRAYSCALE:
					readUncompressedPixelData(f,
						hdr,
						colourMap,
						pixels);
					break;
				case COMPRESSED_MAPPED:
				case COMPRESSED_TRUECOLOR:
				case COMPRESSED_GRAYSCALE:
					readCompressedPixelData(f,
						hdr,
						colourMap,
						pixels);
					break;
				default:
					throw new TArGeDException(
						"Wrong image type"
					);
			}
	}

	private void readUncompressedPixelData(ref File f,
		ref TGAHeader hdr,
		ref Pixel[] colourMap,
		out Pixel[] pixels) {
			auto r = (hdr.ColourMapType == TGAColourMapType.PRESENT)
				? delegate (ubyte[] d) =>
					colourMap[readFromArray!uint(d)]
				: delegate (ubyte[] d) =>
					Pixel(d);
			pixels.length = hdr.Width * hdr.Height;	// TODO ALLOC

			ubyte[] buf = new ubyte[hdr.PixelDepth/8];
			foreach(ref p; pixels) {
				f.rawRead(buf);
				p = r(buf);
			}
	}

	private void readCompressedPixelData(ref File f,
		ref TGAHeader hdr,
		ref Pixel[] colourMap,
		out Pixel[] pixels) {
			auto r = (hdr.ColourMapType == TGAColourMapType.PRESENT)
				? delegate (ubyte[] d) =>
					colourMap[readFromArray!uint(d)]
				: delegate (ubyte[] d) =>
					Pixel(d);
		pixels.length = hdr.Width * hdr.Height;	// TODO ALLOC

		ubyte[] buf = new ubyte[hdr.PixelDepth/8+1];
		size_t i;
		while(i < hdr.Width * hdr.Height) {
			f.rawRead(buf);
			size_t rep = buf[0] & 0x7F;
			pixels[i] = r(buf[0..hdr.PixelDepth/8]);
			i++;
			if(buf[0] & 0x80) {
				for(size_t j = 0; j < rep; j++, i++)
					pixels[i] =
						r(buf[1 .. hdr.PixelDepth/8+1]);
			} else {
				for(size_t j=0; j < rep; j++, i++) {
					f.rawRead(buf[0..hdr.PixelDepth/8]);
					pixels[i] =
						r(buf[0..hdr.PixelDepth/8]);
				}
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

	@property void Pixels(Pixel[] data) {
		this.ImagePixels = data;
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

	@property void ColourMap(Pixel[] data) {
		this.ImageColourMap = data;
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

	@property void Gamma(TGAGamma gamma) {
		if(!gamma.isCorrect)
			throw new TArGeDException("Gamma value is invalid");
		this.ImageExtArea.Gamma = gamma;
	}
}

