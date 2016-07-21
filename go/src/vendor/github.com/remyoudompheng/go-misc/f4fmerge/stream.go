package main

import (
	"encoding/binary"
	"io"
)

// Audio/video demuxing
// See also E.3 The FLV File Body and E.4 FLV Tag Definition

func handleMovieData(box Box) []Frame {
	if box.Type != "mdat" {
		panic("not a mdat box")
	}
	s := box.Data
	var frames []Frame
	for len(s) > 0 {
		typ := s[0] & 0x1f
		filter := (s[0]>>5)&1 != 0
		size := uint32(s[1])<<16 |
			uint32(s[2])<<8 |
			uint32(s[3])
		stamp := uint32(s[4])<<16 |
			uint32(s[5])<<8 |
			uint32(s[6]) |
			uint32(s[7])<<24
		// 3 bytes for StreamID == 0
		f := Frame{
			Filtered: filter,
			Type:     typ,
			Stamp:    stamp,
			Data:     s[11 : 11+size],
		}
		frames = append(frames, f)
		s = s[11+size+4:]
	}
	return frames
}

type Frame struct {
	Filtered bool
	Type     byte
	Stamp    uint32
	Data     []byte
}

func (f *Frame) WriteTo(w io.Writer) error {
	var hdr [11]byte
	hdr[0] = f.Type
	if f.Filtered {
		hdr[0] |= 1 << 5
	}
	// size
	binary.BigEndian.PutUint32(hdr[7:], uint32(len(f.Data)))
	copy(hdr[1:4], hdr[8:11])
	// stamp
	binary.BigEndian.PutUint32(hdr[7:], f.Stamp)
	copy(hdr[4:7], hdr[8:11])
	// stream id
	hdr[8], hdr[9], hdr[10] = 0, 0, 0
	_, err := w.Write(hdr[:])
	if err != nil {
		return err
	}
	_, err = w.Write(f.Data)
	if err != nil {
		return err
	}
	binary.BigEndian.PutUint32(hdr[0:4], uint32(len(f.Data)+len(hdr)))
	_, err = w.Write(hdr[:4])
	return err
}

func (f *Frame) IsSeqHeader() bool {
	switch f.Type {
	case 8: // Audio
		if f.Data[0]>>4 == 10 && f.Data[1] == 0 {
			// AAC sequence header
			return true
		}
	case 9: // Video
		if f.Data[0]&0xf == 7 && f.Data[1] == 0 {
			// AVC sequence header
			return true
		}
	}
	return false
}

func (f *Frame) Describe() string {
	var desc string
	switch f.Type {
	case 8: // Audio
		c := f.Data[0]
		if c>>4 == 10 && f.Data[1] == 0 {
			return "AAC sequence header"
		}
		fmt := c >> 4 & 0xf
		desc += soundFormat[fmt]
		rate := c >> 2 & 0x3
		desc += ", " + soundRateStr[rate]
		size := c >> 1 & 0x1
		desc += ", " + soundSizeStr[size]
		typ := c & 0x1
		desc += ", " + soundTypeStr[typ]
	case 9: // Video
		c := f.Data[0]
		if c&0xf == 7 && f.Data[1] == 0 {
			return "AVC sequence header"
		}
		frm := c >> 4 & 0xf
		desc += frameStr[frm]
		codec := c & 0xf
		desc += ", " + vcodecStr[codec]
	default:
	}
	return desc
}

var soundFormat = [...]string{
	0:  "PCM",
	1:  "ADPCM",
	2:  "MP3",
	10: "AAC",
	11: "Speex",
	15: "",
}

var soundRateStr = [...]string{
	"5.5kHz",
	"11kHz",
	"22kHz",
	"44kHz",
}

var soundSizeStr = [...]string{
	"8-bit",
	"16-bit",
}

var soundTypeStr = [...]string{"mono", "stereo"}

var frameStr = [...]string{
	1:  "key frame",
	2:  "inter frame",
	3:  "disposable inter frame",
	4:  "generated key frame",
	5:  "info/cmd frame",
	15: "",
}

var vcodecStr = [...]string{
	1:  "H.263",
	4:  "VP6",
	5:  "VP6 alpha",
	7:  "AVC",
	15: "",
}
