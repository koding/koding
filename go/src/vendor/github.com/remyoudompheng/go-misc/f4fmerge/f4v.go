package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"io"
	"log"
)

// Comments refer to the FLV spec available at
// http://www.adobe.com/devnet/f4v.html

func ReadBox(r io.Reader) (box Box, err error) {
	// see 1.3 F4V box format
	// (length uint32) (tag [4]byte) (len64 uint64)? (data [...]byte)
	var buf [8]byte
	var prefixLen int
	n, err := io.ReadFull(r, buf[:])
	if n == 0 && err == io.EOF {
		return Box{}, io.EOF
	}
	prefixLen += 8
	defer func() {
		if err == io.EOF {
			err = io.ErrUnexpectedEOF
		}
	}()
	if err != nil {
		return Box{}, err
	}
	length := int64(binary.BigEndian.Uint32(buf[:4]))
	typ := string(buf[4:])
	if length == 1 {
		_, err = io.ReadFull(r, buf[:])
		if err != nil {
			return Box{}, err
		}
		length = int64(binary.BigEndian.Uint64(buf[:]))
		prefixLen += 8
	}
	box = Box{Type: typ, Data: make([]byte, length-int64(prefixLen))}
	n, err = io.ReadFull(r, box.Data)
	return box, err
}

type Box struct {
	Type string // 4 bytes
	Data []byte
}

type BootstrapInfo struct {
	Version             byte    // 0 or 1
	_                   [3]byte // reserved
	BstInfo             uint32
	Flags               byte // profile:2,live:1,update:1,reserved:4
	TimeScale           uint32
	CurrentMediaTime    uint64
	SmpteTimeCodeOffset uint64
}

// 2.11.2 Bootstrap Info boax
func handleBootstrapInfo(box Box) (BootstrapInfo, error) {
	r := bytes.NewBuffer(box.Data)
	var h BootstrapInfo
	err := binary.Read(r, binary.BigEndian, &h)
	if err != nil {
		return h, err
	}
	log.Printf("%+v", h)

	movieId, err := r.ReadString(0)
	if err != nil {
		log.Panicf("could not read movie ID")
	}
	srvCount, err := r.ReadByte()
	if srvCount != 0 {
		log.Panicf("unsupported server entry")
	}
	qualCount, err := r.ReadByte()
	if qualCount != 0 {
		log.Panicf("unsupported quality entry")
	}
	drmData, err := r.ReadString(0)
	if err != nil {
		log.Panicf("could not read DRM data")
	}
	metaData, err := r.ReadString(0)
	if err != nil {
		log.Panicf("could not read metadata")
	}
	segCount, err := r.ReadByte()
	if err != nil {
		log.Panicf("could not read segment tables")
	}
	for i := 0; i < int(segCount); i++ {
		err = parseSegmentRunTable(r)
		if err != nil {
			return h, fmt.Errorf("asrt[%d]: %s", i, err)
		}
	}
	fragCount, err := r.ReadByte()
	if err != nil {
		log.Panicf("could not read fragment tables")
	}
	for i := 0; i < int(fragCount); i++ {
		err = parseFragmentRunTable(r)
		if err != nil {
			return h, fmt.Errorf("afrt[%d]: %s", i, err)
		}
	}
	_ = movieId
	_ = drmData
	_ = metaData
	return h, nil
}

func parseSegmentRunTable(r *bytes.Buffer) error {
	b, err := ReadBox(r)
	if err != nil {
		return err
	}
	if b.Type != "asrt" {
		return fmt.Errorf("%s: not a Segment Run Table box", b.Type)
	}
	r = bytes.NewBuffer(b.Data)
	r.Next(4)
	qualities, err := readStringList(r)
	_ = qualities
	if err != nil {
		return parseError{"quality entries", err}
	}
	var runCount uint32
	err = binary.Read(r, binary.BigEndian, &runCount)
	if err != nil {
		return parseError{"run count", err}
	}
	run := make([][2]uint32, runCount)
	err = binary.Read(r, binary.BigEndian, &run)
	if err != nil {
		return parseError{"segment runs", err}
	}
	log.Println(run)
	return nil
}

func parseFragmentRunTable(r *bytes.Buffer) error {
	b, err := ReadBox(r)
	if err != nil {
		return err
	}
	if b.Type != "afrt" {
		return fmt.Errorf("%s: not a Segment Run Table box", b.Type)
	}
	r = bytes.NewBuffer(b.Data)
	r.Next(4)
	var timeScale uint32
	err = binary.Read(r, binary.BigEndian, &timeScale)
	if err != nil {
		return parseError{"time scale", err}
	}
	qualities, err := readStringList(r)
	_ = qualities
	if err != nil {
		return parseError{"quality entries", err}
	}
	var fragCount uint32
	err = binary.Read(r, binary.BigEndian, &fragCount)
	if err != nil {
		return parseError{"run count", err}
	}

	type fragInfo struct {
		First      uint32
		FirstStamp uint64
		Duration   uint32
	}
	run := make([]fragInfo, fragCount)
	err = binary.Read(r, binary.BigEndian, &run)
	if err != nil {
		return parseError{"fragment runs", err}
	}
	log.Printf("%+v", run)
	return nil

}

func readStringList(r *bytes.Buffer) ([]string, error) {
	count, err := r.ReadByte()
	if err != nil {
		return nil, fmt.Errorf("missing list length")
	}
	var s []string
	for i := 0; i < int(count); i++ {
		str, err := r.ReadString(0)
		if err != nil {
			return nil, fmt.Errorf("expected %d strings, got %d", count, len(s))
		}
		s = append(s, str)
	}
	return s, nil
}

type parseError struct {
	object string
	err    error
}

func (e parseError) Error() string {
	return "could not parse " + e.object + ": " + e.err.Error()
}
