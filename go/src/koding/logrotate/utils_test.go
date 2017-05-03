package logrotate_test

import (
	"bytes"
	"compress/gzip"
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"io"
	"io/ioutil"
	"net/url"
	"strings"

	"koding/logrotate"
)

type UserBucket map[string][]byte

func (ub UserBucket) Put(key string, rs io.ReadSeeker) (u *url.URL, err error) {

	var r io.Reader = rs
	var origKey = key

	if i := strings.LastIndex(key, "."); i != -1 {
		origKey = key[:i]
	}

	if logrotate.IsGzip(origKey) {
		if r, err = gzip.NewReader(rs); err != nil {
			return nil, err
		}
	}

	p, err := ioutil.ReadAll(r)
	if err != nil {
		return nil, err
	}

	ub[key] = p

	return ub.URL(key), nil
}

func (ub UserBucket) URL(string) *url.URL {
	return &url.URL{
		Scheme: "memory",
		Path:   "0xDD",
	}
}

func reader(offset, size int64) io.ReadSeeker {
	return strings.NewReader(content[int(offset):int(size)])
}

func sum(s string) string {
	p := sha1.Sum([]byte(s))
	return hex.EncodeToString(p[:])
}

func equal(r1, r2 io.Reader) error {
	p1, err := ioutil.ReadAll(r1)
	if err != nil {
		return fmt.Errorf("reading r1: %s", err)
	}

	p2, err := ioutil.ReadAll(r2)
	if err != nil {
		return fmt.Errorf("reading r2: %s", err)
	}

	if bytes.Compare(p1, p2) != 0 {
		return fmt.Errorf("%q != %q", p1, p2)
	}

	return nil
}
