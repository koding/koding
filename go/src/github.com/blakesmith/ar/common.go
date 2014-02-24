package ar

import (
	"time"
)

const (
	HEADER_BYTE_SIZE = 60
	GLOBAL_HEADER = "!<arch>\n"
)

type Header struct {
	Name string
	ModTime time.Time
	Uid int
	Gid int
	Mode int64
	Size int64
}

type slicer []byte

func (sp *slicer) next(n int) (b []byte) {
	s := *sp
	b, *sp = s[0:n], s[n:]
	return
}
