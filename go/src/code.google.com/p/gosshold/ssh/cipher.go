// Copyright 2011 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package ssh

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rc4"
)

// streamDump is used to dump the initial keystream for stream ciphers. It is a
// a write-only buffer, and not intended for reading so do not require a mutex.
var streamDump [512]byte

// noneCipher implements cipher.Stream and provides no encryption. It is used
// by the transport before the first key-exchange.
type noneCipher struct{}

func (c noneCipher) XORKeyStream(dst, src []byte) {
	copy(dst, src)
}

func newAESCTR(key, iv []byte) (cipher.Stream, error) {
	c, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	return cipher.NewCTR(c, iv), nil
}

func newRC4(key, iv []byte) (cipher.Stream, error) {
	return rc4.NewCipher(key)
}

type cipherMode struct {
	keySize    int
	ivSize     int
	skip       int
	createFunc func(key, iv []byte) (cipher.Stream, error)
}

func (c *cipherMode) createCipher(key, iv []byte) (cipher.Stream, error) {
	if len(key) < c.keySize {
		panic("ssh: key length too small for cipher")
	}
	if len(iv) < c.ivSize {
		panic("ssh: iv too small for cipher")
	}

	stream, err := c.createFunc(key[:c.keySize], iv[:c.ivSize])
	if err != nil {
		return nil, err
	}

	for remainingToDump := c.skip; remainingToDump > 0; {
		dumpThisTime := remainingToDump
		if dumpThisTime > len(streamDump) {
			dumpThisTime = len(streamDump)
		}
		stream.XORKeyStream(streamDump[:dumpThisTime], streamDump[:dumpThisTime])
		remainingToDump -= dumpThisTime
	}

	return stream, nil
}

// Specifies a default set of ciphers and a preference order. This is based on
// OpenSSH's default client preference order, minus algorithms that are not
// implemented.
var DefaultCipherOrder = []string{
	"aes128-ctr", "aes192-ctr", "aes256-ctr",
	"arcfour256", "arcfour128",
}

// cipherModes documents properties of supported ciphers. Ciphers not included
// are not supported and will not be negotiated, even if explicitly requested in
// ClientConfig.Crypto.Ciphers.
var cipherModes = map[string]*cipherMode{
	// Ciphers from RFC4344, which introduced many CTR-based ciphers. Algorithms
	// are defined in the order specified in the RFC.
	"aes128-ctr": {16, aes.BlockSize, 0, newAESCTR},
	"aes192-ctr": {24, aes.BlockSize, 0, newAESCTR},
	"aes256-ctr": {32, aes.BlockSize, 0, newAESCTR},

	// Ciphers from RFC4345, which introduces security-improved arcfour ciphers.
	// They are defined in the order specified in the RFC.
	"arcfour128": {16, 0, 1536, newRC4},
	"arcfour256": {32, 0, 1536, newRC4},
}

// defaultKeyExchangeOrder specifies a default set of key exchange algorithms
// with preferences.
var defaultKeyExchangeOrder = []string{
	// P384 and P521 are not constant-time yet, but since we don't
	// reuse ephemeral keys, using them for ECDH should be OK.
	kexAlgoECDH256, kexAlgoECDH384, kexAlgoECDH521,
	kexAlgoDH14SHA1, kexAlgoDH1SHA1,
}
