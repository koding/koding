package nbu

import (
	"encoding/binary"
	"io"
	"os"
	"time"
	"unicode/utf16"
)

// NBU format parser as produced by Nokia Communication Center.

// OpenFile opens a NBU archive for reading.
func OpenFile(filename string) (*Reader, error) {
	f, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	r := &Reader{File: f}
	r.Size, _ = f.Seek(0, os.SEEK_END)
	f.Seek(0, os.SEEK_SET)
	return r, nil
}

type Reader struct {
	File interface {
		io.ReaderAt
		io.Closer
	}
	Size int64
}

// A FileInfo describes a NBU archive metadata.
type FileInfo struct {
	BackupTime time.Time
	IMEI       string
	Model      string
	Name       string
	Firmware   string
	Language   string

	Sections []Section
}

type Section struct {
	Type int
	GUID [2]uint64

	Offset int64
	Length int64

	// For memos, calendar
	Items int64

	// For messages
	Folders map[int]int64 // idx => offset
}

// Close closes the underlying file of r.
func (r *Reader) Close() error { return r.File.Close() }

// Info reads archive metadata and TOC.
func (r *Reader) Info() (info FileInfo, err error) {
	var buf [8]byte
	// Find TOC offset.
	_, err = r.File.ReadAt(buf[:], 0x14)
	if err != nil {
		return
	}
	off := int64(binary.LittleEndian.Uint64(buf[:]))
	// Read metadata.
	debugf("TOC offset: %x", off)
	sec := io.NewSectionReader(r.File, off+0x14, r.Size-off-0x14)
	info.BackupTime, err = readTime(sec)
	for _, s := range []*string{&info.IMEI, &info.Model, &info.Name, &info.Firmware, &info.Language} {
		if err == nil {
			*s, err = readString(sec)
		}
	}
	// skip 20 bytes.
	sec.Seek(0x14, os.SEEK_CUR)
	// here begin the TOC.
	_, err = sec.Read(buf[:4])
	if err != nil {
		return
	}
	parts := binary.LittleEndian.Uint32(buf[:4])
	for p := 0; p < int(parts); p++ {
		var guid [2]uint64
		err := binary.Read(sec, binary.BigEndian, &guid)
		if err != nil {
			return info, err
		}
		off, err := read64(sec)
		if err != nil {
			return info, err
		}
		length, err := read64(sec)
		if err != nil {
			return info, err
		}
		typ := SecERROR
		for i, g := range secUUID {
			if guid == g {
				typ = i
			}
		}
		if typ == SecERROR {
			debugf("unknown section GUID %x", guid)
		}
		debugf("section %x (%s) at offset %x+%x",
			guid, secNames[typ], off, length)
		section := Section{
			Type:   typ,
			GUID:   guid,
			Offset: int64(off),
			Length: int64(length),
		}
		switch typ {
		case SecFS:
			nFiles, _ := read32(sec)
			read32(sec)           // ?
			read32(sec)           // ?
			read32(sec)           // ?
			read32(sec)           // ?
			read32(sec)           // ?
			off, _ := read64(sec) // off
			_, _ = nFiles, off
		case SecContacts:
			nItems, _ := read32(sec) // files
			section.Items = int64(nItems)
			nFolder, _ := read32(sec) // folders
			section.Folders = make(map[int]int64, nFolder)
			for i := 0; i < int(nFolder); i++ {
				idx, _ := read32(sec) // idx
				off, _ := read64(sec) // off
				debugf("folder %d at %x", idx, off)
				section.Folders[int(idx)] = int64(off)
			}

		case SecGroups,
			SecMessages,
			SecMMS,
			SecBookmarks:
			nItems, _ := read32(sec) // files
			section.Items = int64(nItems)
			nFolder, _ := read32(sec) // folders
			section.Folders = make(map[int]int64, nFolder)
			for i := 0; i < int(nFolder); i++ {
				idx, _ := read32(sec) // idx
				off, _ := read64(sec) // off
				debugf("folder %d at %x", idx, off)
				section.Folders[int(idx)] = int64(off)
			}

		case SecCalendar, SecMemo:
			nbMemos, _ := read64(sec)
			debugf("%d memos", nbMemos)
			section.Items = int64(nbMemos)

		case SecSettingsContacts,
			SecSettingsCalendar:
			_, _ = read32(sec)
			_, _ = read32(sec)
		}
		info.Sections = append(info.Sections, section)
	}
	return
}

const (
	SecFS = iota
	SecContacts
	SecGroups
	SecCalendar
	SecMemo
	SecMessages
	SecMMS
	SecBookmarks
	SecSettingsContacts
	SecSettingsCalendar
	SecERROR
)

var secUUID = [...][2]uint64{
	SecFS:        {0x08294b2b0e89174b, 0x977317c24c1adbc8},
	SecContacts:  {0xefd42ed0a3513847, 0x9dd7305c7af068d3},
	SecGroups:    {0x1f0e5865a19f3c49, 0x9e230e25eb240fe1},
	SecCalendar:  {0x16cdf8e8235e5a4e, 0xb735dddff1481222},
	SecMemo:      {0x5c62973bdca75441, 0xa1c3059de3246808},
	SecMessages:  {0x617aefd1aabea149, 0x9d9d155abb4ceb8e},
	SecMMS:       {0x471dd465efe33240, 0x8c7764caa383aa33},
	SecBookmarks: {0x7f77905631f95749, 0x8d96ee445dbebc5a},

	SecSettingsContacts: {0x60c2cb9c7e732441, 0x8d902ec0d9b0b68c},
	SecSettingsCalendar: {0x2dedc72957682245, 0xaed4eb210296a1ee},
}

var secNames = [...]string{
	SecFS:               "Internal files",
	SecContacts:         "Contacts",
	SecGroups:           "Groups",
	SecCalendar:         "Calendar",
	SecMemo:             "Memos",
	SecMessages:         "Messages",
	SecMMS:              "MMS",
	SecBookmarks:        "Bookmarks",
	SecSettingsContacts: "Settings/Contacts",
	SecSettingsCalendar: "Settings/Calendar",
	SecERROR:            "ERROR",
}

func (r *Reader) ReadMessageFolderAt(off int64) (title string, messages []string, err error) {
	sr := io.NewSectionReader(r.File, off, r.Size-off)
	return parseMessageFolder(sr)
}

func (r *Reader) ReadMMSFolderAt(off int64) (title string, messages [][]byte, err error) {
	sr := io.NewSectionReader(r.File, off, r.Size-off)
	return parseMMSFolder(sr)
}

func parseMessageFolder(r io.Reader) (title string, messages []string, err error) {
	_, err = read32(r) // folder id.
	title, err = readString(r)
	if err != nil {
		return
	}
	nMsg, err := read32(r)
	messages = make([]string, 0, nMsg)
	for i := 0; i < int(nMsg); i++ {
		// FIXME: check errors.
		read32(r) // skip
		read32(r) // skip
		msg, err := readLongString(r)
		messages = append(messages, msg)
		if err == io.EOF {
			if i+1 != int(nMsg) {
				err = io.ErrUnexpectedEOF
			} else {
				err = nil
			}
		}
	}
	return
}

func parseMMSFolder(r io.Reader) (title string, messages [][]byte, err error) {
	var buf [8]byte
	_, err = read32(r) // folder id.
	title, err = readString(r)
	if err != nil {
		return
	}
	nMsg, err := read32(r)
	messages = make([][]byte, 0, nMsg)
	for i := 0; i < int(nMsg); i++ {
		// FIXME: check errors.
		read32(r) // 0x2c
		read32(r) // 0x1500
		// addresses
		r.Read(buf[:1])
		read32(r)
		read32(r)
		readString(r)
		read32(r) // 0
		read64(r) // ?
		read64(r) // ?
		length, err := read32(r)
		if err != nil {
			return title, messages, err
		}
		data := make([]byte, length)
		_, err = io.ReadFull(r, data)
		messages = append(messages, data)
		if err == io.EOF {
			if i+1 != int(nMsg) {
				err = io.ErrUnexpectedEOF
			} else {
				err = nil
			}
		}
		if err != nil {
			return title, messages, err
		}
	}
	return
}

// Utility functions.

// From MSDN: "A Windows file time is a 64-bit value that represents the number
// of 100-nanosecond intervals that have elapsed since 12:00 midnight, January
// 1, 1601 A.D. (C.E.) Coordinated Universal Time (UTC)."

var baseWinTime = time.Date(1601, 1, 1, 0, 0, 0, 0, time.UTC)

func readTime(r io.Reader) (time.Time, error) {
	// time is stored as: high 32 bits, low 32 bits (little-endian).
	var buf [8]byte
	_, err := io.ReadFull(r, buf[:])
	if err != nil {
		return baseWinTime, err
	}
	hi := binary.LittleEndian.Uint32(buf[:4])
	lo := binary.LittleEndian.Uint32(buf[4:])
	ticks := uint64(hi)<<32 | uint64(lo)
	days := ticks / (86400 * 1e7)
	ticks %= 86400 * 1e7
	secs, nsec := ticks/1e7, (ticks%1e7)*100
	return baseWinTime.
		AddDate(0, 0, int(days)).
		Add(time.Duration(secs) * time.Second).
		Add(time.Duration(nsec) * time.Nanosecond), nil
}

func readString(r io.Reader) (string, error) {
	// Little endian 16 bit length + UTF-16LE string.
	var buf [2]byte
	_, err := io.ReadFull(r, buf[:])
	if err != nil {
		return "", err
	}
	length := int(buf[1])<<8 | int(buf[0])
	s := make([]uint16, length)
	err = binary.Read(r, binary.LittleEndian, s)
	return string(utf16.Decode(s)), err
}

func readLongString(r io.Reader) (string, error) {
	// Little endian 32 bit byte length + UTF-16LE string.
	var length uint32
	err := binary.Read(r, binary.LittleEndian, &length)
	if err != nil {
		return "", err
	}
	s := make([]uint16, length/2)
	err = binary.Read(r, binary.LittleEndian, s)
	return string(utf16.Decode(s)), err
}

func read32(r io.Reader) (uint32, error) {
	var buf [4]byte
	_, err := io.ReadFull(r, buf[:])
	return binary.LittleEndian.Uint32(buf[:]), err
}
func read64(r io.Reader) (uint64, error) {
	var buf [8]byte
	_, err := io.ReadFull(r, buf[:])
	return binary.LittleEndian.Uint64(buf[:]), err
}
