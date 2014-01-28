package ar

import (
	"io"
	"io/ioutil"
	"os"
	"strconv"
	"time"
)

// Provides read access to an ar archive.
// Call next to skip files
// 
// Example:
//	reader := NewReader(f)
//	var buf bytes.Buffer
//	for {
//		_, err := reader.Next()
//		if err == io.EOF {
//			break
//		}
//		if err != nil {
//			t.Errorf(err.Error())
//		}
//		io.Copy(&buf, reader)
//	}

type Reader struct {
	r io.Reader
	nb int64
	pad int64
}

// Copies read data to r. Strips the global ar header.
func NewReader(r io.Reader) *Reader {
	io.CopyN(ioutil.Discard, r, 8) // Discard global header

	return &Reader{r: r}
}

func (rd *Reader) string(b []byte) string {
	i := len(b)-1
	for i > 0 && b[i] == 32 {
		i--
	}

	return string(b[0:i+1])
}

func (rd *Reader) numeric(b []byte) int64 {
	i := len(b)-1
	for i > 0 && b[i] == 32 {
		i--
	}

	n, _ := strconv.ParseInt(string(b[0:i+1]), 10, 64)

	return n
}

func (rd *Reader) octal(b []byte) int64 {
	i := len(b)-1
	for i > 0 && b[i] == 32 {
		i--
	}

	n, _ := strconv.ParseInt(string(b[3:i+1]), 8, 64)

	return n
}

func (rd *Reader) skipUnread() error {
	skip := rd.nb + rd.pad
	rd.nb, rd.pad = 0, 0
	if seeker, ok := rd.r.(io.Seeker); ok {
		_, err := seeker.Seek(skip, os.SEEK_CUR)
		return err
	}

	_, err := io.CopyN(ioutil.Discard, rd.r, skip)
	return err
}

func (rd *Reader) readHeader() (*Header, error) {
	headerBuf := make([]byte, HEADER_BYTE_SIZE)
	if _, err := io.ReadFull(rd.r, headerBuf); err != nil {
		return nil, err
	}

	header := new(Header)
	s := slicer(headerBuf)

	header.Name = rd.string(s.next(16))
	header.ModTime = time.Unix(rd.numeric(s.next(12)), 0)
	header.Uid = int(rd.numeric(s.next(6)))
	header.Gid = int(rd.numeric(s.next(6)))
	header.Mode = rd.octal(s.next(8))
	header.Size = rd.numeric(s.next(10))

	rd.nb = int64(header.Size)
	if header.Size%2 == 1 {
		rd.pad = 1
	} else {
		rd.pad = 0
	}

	return header, nil
}

// Call Next() to skip to the next file in the archive file.
// Returns a Header which contains the metadata about the 
// file in the archive.
func (rd *Reader) Next() (*Header, error) {
	err := rd.skipUnread()
	if err != nil {
		return nil, err
	}
	
	return rd.readHeader()
}

// Read data from the current entry in the archive.
func (rd *Reader) Read(b []byte) (n int, err error) {
	if rd.nb == 0 {
		return 0, io.EOF
	}
	if int64(len(b)) > rd.nb {
		b = b[0:rd.nb]
	}
	n, err = rd.r.Read(b)
	rd.nb -= int64(n)

	return
}