package main

import (
	"encoding/binary"
	"io"
)

// File layout
//
// Header (big endian U32)
// - number of pages
// - width in pixels
// - height in pixels
// - X grid size
// - Y grid size
// for each page:
//    - size of each tile in bytes (X x Y)
//    - size of full page view in bytes
//    - size of thumbnail
//
// For each page:
//    X*Y Tiles (JPEG)
//    Full page image (JPEG)
// For each page:
//    Thumbnail (JPEG)

type Header struct {
	Pages         uint32
	Width, Height uint32
	NX, NY        uint32
}

type MVZ struct {
	Header
	// for each page: tiles + large + ???
	ImgSizes [][]uint32
}

func readHeader(r io.Reader) MVZ {
	var h Header
	binary.Read(r, binary.BigEndian, &h)

	m := MVZ{Header: h}
	for i := 0; i < int(h.Pages); i++ {
		sizes := make([]uint32, h.NX*h.NY+1+1)
		binary.Read(r, binary.BigEndian, sizes)
		m.ImgSizes = append(m.ImgSizes, sizes)
	}
	return m
}
