package logrotate

import "io"

// This file exports unexported symbols used in tests. Those symbols
// are not used outside the package, but are important enough
// to have stable api / behavior.

func Rotate(content io.ReadSeeker, meta *Metadata) (*MetadataPart, error) {
	return rotate(content, meta)
}

func IsGzip(key string) bool {
	return isGzip(key)
}
