# node-buffertools

Utilities for manipulating buffers.

## Installing the module

Easy! With [npm](http://npmjs.org/):

	npm install buffertools

From source:

	node-waf configure build install

Now you can include the module in your project.

	require('buffertools');
	new Buffer(42).clear();

## Methods

Note that most methods that take a buffer as an argument, will also accept a string.

### Buffer.clear()

Clear the buffer. This is equivalent to `Buffer.fill(0)`.
Returns the buffer object so you can chain method calls.

### Buffer.compare(buffer|string)

Lexicographically compare two buffers. Returns a number smaller than 1
if a < b, zero if a == b or a number larger than 1 if a > b.

Buffers are considered equal when they are of the same length and contain
the same binary data.

Smaller buffers are considered to be less than larger ones. Some buffers
find this hurtful.

### Buffer.concat(a, b, c, ...)
### buffertools.concat(a, b, c, ...)

Concatenate two or more buffers/strings and return the result. Example:

	// identical to new Buffer('foobarbaz')
	a = new Buffer('foo');
	b = new Buffer('bar');
	c = a.concat(b, 'baz');
	console.log(a, b, c); // "foo bar foobarbaz"

	// static variant
	buffertools.concat('foo', new Buffer('bar'), 'baz');

### Buffer.equals(buffer|string)

Returns true if this buffer equals the argument, false otherwise.

Buffers are considered equal when they are of the same length and contain
the same binary data.

Caveat emptor: If your buffers contain strings with different character encodings,
they will most likely *not* be equal.

### Buffer.fill(integer|string|buffer)

Fill the buffer (repeatedly if necessary) with the argument.
Returns the buffer object so you can chain method calls.

### Buffer.fromHex()

Assumes this buffer contains hexadecimal data (packed, no whitespace)
and decodes it into binary data. Returns a new buffer with the decoded
content. Throws an exception if non-hexadecimal data is encountered.

### Buffer.indexOf(buffer|string)

Search this buffer for the first occurrence of the argument.
Returns the zero-based index or -1 if there is no match.

### Buffer.reverse()

Reverse the content of the buffer in place. Example:

	b = new Buffer('live');
	b.reverse();
	console.log(b); // "evil"

### Buffer.toHex()

Returns the contents of this buffer encoded as a hexadecimal string.

## Classes

Singular, actually. To wit:

## WritableBufferStream

This is a regular node.js [writable stream](http://nodejs.org/docs/v0.3.4/api/streams.html#writable_Stream)
that accumulates the data it receives into a buffer.

Example usage:

	// slurp stdin into a buffer
	process.stdin.resume();
	ostream = new WritableBufferStream();
	util.pump(process.stdin, ostream);
	console.log(ostream.getBuffer());

The stream never emits 'error' or 'drain' events.

### WritableBufferStream.getBuffer()

Return the data accumulated so far as a buffer.

## TODO

* Logical operations on buffers (AND, OR, XOR).
* Add lastIndexOf() functions.
