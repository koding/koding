'use strict';

/**
 * Buffer.toByteArray() - Returns an array of bytes from the Buffer argument
 * 
 * @param {Buffer} buffer
 * @returns {Array}
 */
if ( ! Buffer.prototype.toByteArray) {
	Buffer.prototype.toByteArray = function () {
		return Array.prototype.slice.call(this, 0);
	};
}
