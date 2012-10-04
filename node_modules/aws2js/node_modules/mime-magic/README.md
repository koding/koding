## About

MIME type detection library for node.js. Unlike the [mime](https://github.com/broofa/node-mime) module, mime-magic does not return the type by interpreting the file extension. Instead it uses the [libmagic(3)](http://linux.die.net/man/3/libmagic) library which provides the result by reading the "magic number" of the file itself.

Currently it provides just a simple [file(1)](http://linux.die.net/man/1/file) wrapper to get the things moving, but in the long run, the purpose of this module is to provide proper node.js libmagic bindings. The file(1) source tree is provided along with this package. It is built during the installation process. The module aims to use the latest available file version along with the up-to-date magic database.

The Windows version of file(1) is bundled with the package. It is a native binary build with MinGW and compressed with UPX.

## Installation

Either manually clone this repository into your node_modules directory, run `make build` (under unices), or the recommended method:

> npm install mime-magic

## Usage mode

```javascript
var mime = require('mime-magic');

mime.fileWrapper('/path/to/foo.pdf', function (err, type) {
	if (err) {
		console.error(err.message);
		// ERROR: cannot open `/path/to/foo.pdf' (No such file or directory)
	} else {
		console.log('Detected mime type: %s', type);
		// application/pdf
	}
});
```

You may use an array of paths. The callback gets an array of mimes:

```javascript
var files = [
	'/path/to/foo.pdf',
	'/path/to/foo.txt'
];

mime.fileWrapper(files, function (err, types) {
	if (err) {
		console.error(err.message);
		// ERROR: cannot open `/path/to/foo.pdf' (No such file or directory)
		// ERROR: cannot open `/path/to/foo.txt' (No such file or directory)
	} else {
		console.log(types);
		// ['application/pdf', 'text/plain']
	}
});
```

Under Windows, you must escape the backslash separators of the path argument:

```javascript
mime.fileWrapper('C:\\path\\to\\foo.pdf', function (err, type) {
	// do something
});
```

You may also pass a path that uses forward slashes as separators:

```javascript
mime.fileWrapper('C:/path/to/foo.pdf', function (err, type) {
	// do something
});
```

Passing relative paths is supported. The fileWrapper uses child_process.execFile() behind the scenes, therefore the err argument contains the information returned by the execFile() method itself plus the error message returned by file(1).

## Notices

The module is developed under Ubuntu 12.04, and Windows 7. It is tested under OS X Lion, and FreeBSD 9.0. Other platforms may be supported, but the behavior is untested.

The Windows binaries are built by myself under Windows 7 / MinGW + MSYS. The binaries are packed with the [UPX](http://upx.sourceforge.net/) tool in order to make them smaller.

Here's the virustotal.com analysis:

 * [file.exe](https://www.virustotal.com/file/8e4b6b373538ff98be4df14af0f6ccbd6b1306febc0a37a2a5c7d26f6d8f30f6/analysis/1330428088/) (unpacked)
 * [file.exe](https://www.virustotal.com/file/bf1a01443588e75be0a0b674da0d0467e4203833c4de7a9a1507bffe46a57830/analysis/1330427980/) (packed)
 * [libmagic-1.dll](https://www.virustotal.com/file/0543b99145a57ab425fe48c7613ff85c32185554e6539df1df1ddaf8584755d8/analysis/1330428015/) (packed)
 * [libgnurx-0.dll](https://www.virustotal.com/file/fabb4a8ace8b841e418293fbd41fcb14dd851b1c1e33acd0414669a500cc9540/analysis/1330428002/) (packed)

Please notice that some antiviruses may throw false positives.

## Contributors

 * [Felix Chan](https://github.com/felixchan) - [#1](https://github.com/SaltwaterC/mime-magic/pull/1): couldn't use fileWrapper more than once unless restarted server.
 * [eddyb](https://github.com/eddyb) - [#3](https://github.com/SaltwaterC/mime-magic/pull/3): support for arrays of paths, with the callback getting an array of mime-types.
