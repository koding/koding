// package ar implements reading of ar archives.
package ar

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"time"
)

type Reader struct {
	rd          io.Reader
	seenHeader  bool
	oddSize     bool
	entryReader io.LimitedReader
}

func NewReader(r io.Reader) *Reader { return &Reader{rd: r} }

var errInvalidMagic = errors.New("invalid magic bytes, expected !<arch>")
var errBadFileHeader = errors.New("invalid file header, should end with '`' and newline")

type errIO struct {
	Context string
	Err     error
}

func (e errIO) Error() string { return fmt.Sprintf("error while %s: %s", e.Context, e.Err) }

// Next advances to the next entry in the ar archive
func (r *Reader) Next() (*Header, error) {
	var buf [60]byte
	if !r.seenHeader {
		// read magic bytes
		_, err := io.ReadFull(r.rd, buf[:8])
		if err != nil {
			return nil, errIO{Context: "reading magic bytes", Err: err}
		}
		if !bytes.Equal(buf[:8], []byte("!<arch>\n")) {
			return nil, errInvalidMagic
		}
		r.seenHeader = true
	}
	// skip leftover data from a previous entry.
	left := r.entryReader.N
	if r.oddSize {
		left++
	}
	if left > 0 {
		_, err := io.CopyN(ioutil.Discard, r.rd, left)
		if err != nil {
			return nil, errIO{Context: "skipping data", Err: err}
		}
	}
	n, err := io.ReadFull(r.rd, buf[:60])
	if n == 0 && err == io.EOF {
		return nil, io.EOF
	}
	if err != nil {
		return nil, errIO{Context: "reading file header", Err: err}
	}
	hdr, err := parseHeader(&buf)
	if err != nil {
		return nil, errIO{Context: "parsing file header", Err: err}
	}
	r.oddSize = hdr.Size%2 == 1
	r.entryReader.R = r.rd
	r.entryReader.N = hdr.Size
	return hdr, nil
}

// Read reads from the current entry in the archive. Upon EOF,
// Next should be called
func (r *Reader) Read(s []byte) (int, error) { return r.entryReader.Read(s) }

type Header struct {
	Name  string
	Stamp time.Time
	UID   int
	GID   int
	Mode  os.FileMode
	Size  int64
}

func parseHeader(line *[60]byte) (hdr *Header, err error) {
	s := string(line[:])
	hdr = new(Header)
	hdr.Name = strings.TrimRight(s[:16], " ")
	stamp, err := strconv.Atoi(strings.TrimRight(s[16:28], " "))
	if err != nil {
		return nil, err
	}
	hdr.Stamp = time.Unix(int64(stamp), 0)
	hdr.UID, err = strconv.Atoi(strings.TrimRight(s[28:34], " "))
	if err != nil {
		return nil, err
	}
	hdr.GID, err = strconv.Atoi(strings.TrimRight(s[34:40], " "))
	if err != nil {
		return nil, err
	}
	mode, err := strconv.ParseInt(strings.TrimRight(s[40:48], " "), 8, 32)
	if err != nil {
		return nil, err
	}
	hdr.Mode = os.FileMode(mode)
	hdr.Size, err = strconv.ParseInt(strings.TrimRight(s[48:58], " "), 10, 64)
	if s[58:60] != "`\n" {
		return nil, errBadFileHeader
	}
	return hdr, nil
}
