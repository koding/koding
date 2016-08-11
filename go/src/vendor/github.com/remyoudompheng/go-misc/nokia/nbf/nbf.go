// package nbf gives access to data from Nokia NBF archives.
package nbf

import (
	"archive/zip"
	"bytes"
	"io/ioutil"
	"log"
	"path"
	"sort"
	"strings"
	"time"
)

// OpenFile opens a NBF archive for reading.
func OpenFile(filename string) (*Reader, error) {
	z, err := zip.OpenReader(filename)
	if err != nil {
		return nil, err
	}
	return &Reader{z: z}, nil
}

type Reader struct {
	z *zip.ReadCloser
}

func (r *Reader) Close() error {
	return r.z.Close()
}

type SMS struct {
	Type  int // 0: incoming, 1: outgoing
	Peer  string
	Peers []string
	When  time.Time
	Text  string
}

func (r *Reader) Inbox() ([]SMS, error) {
	msgs := make([]SMS, 0, len(r.z.File)/4)

	type multiKey struct {
		Peer string
		Ref  int
	}
	multiparts := make(map[multiKey][]userData)
	baseMsg := make(map[multiKey]SMS)
	for _, f := range r.z.File {
		if !strings.HasPrefix(f.Name, "predefmessages/1/") {
			continue
		}
		base := path.Base(f.Name)
		fr, err := f.Open()
		if err != nil {
			log.Printf("cannot read %s: %s", base, err)
			continue
		}
		blob, err := ioutil.ReadAll(fr)
		if err != nil {
			log.Printf("cannot read %s: %s", base, err)
			continue
		}
		m, err := parseMessage(blob)
		if err != nil {
			log.Printf("cannot parse %s: %s", base, err)
			continue
		}

		msg := m.Msg.(deliverMessage)
		sms := SMS{
			Type:  int(msg.MsgType),
			Peer:  msg.FromAddr,
			Peers: m.Peers,
			When:  msg.SMSCStamp,
			Text:  msg.UserData(),
		}

		if msg.Concat {
			key := multiKey{Peer: sms.Peer, Ref: msg.Ref}
			parts := append(multiparts[key], msg.userData)
			if msg.Part == 1 {
				baseMsg[key] = sms
			}
			if len(parts) == msg.NParts {
				delete(multiparts, key)
				sms := baseMsg[key]
				delete(baseMsg, key)
				sms.Text = mergeConcatSMS(parts, msg.Unicode)
				msgs = append(msgs, sms)
			} else {
				multiparts[key] = parts
			}
		} else {
			msgs = append(msgs, sms)
		}
	}
	sort.Sort(smsByDate(msgs))
	return msgs, nil
}

func (r *Reader) Outbox() ([]SMS, error) {
	msgs := make([]SMS, 0, len(r.z.File)/4)

	type multiKey struct {
		Peer string
		Ref  int
	}
	multiparts := make(map[multiKey][]userData)
	baseMsg := make(map[multiKey]SMS)

	for _, f := range r.z.File {
		if !strings.HasPrefix(f.Name, "predefmessages/3/") {
			continue
		}
		base := path.Base(f.Name)
		info, err := parseNBFFilename(base)
		if err != nil {
			log.Printf("invalid entry name %q: %s", base, err)
			continue
		}
		fr, err := f.Open()
		if err != nil {
			log.Printf("cannot read %s: %s", base, err)
			continue
		}
		blob, err := ioutil.ReadAll(fr)
		if err != nil {
			log.Printf("cannot read %s: %s", base, err)
			continue
		}
		m, err := parseMessage(blob)
		if err != nil {
			log.Printf("cannot parse %s: %s", base, err)
			continue
		}

		msg := m.Msg.(submitMessage)
		if m.Peer == "" && len(m.Peers) == 0 {
			log.Printf("WARN: empty peer in %s", base)
		}
		sms := SMS{
			Type:  int(msg.MsgType),
			Peer:  m.Peer,
			Peers: m.Peers,
			When:  DosTime(info.Timestamp).Local(),
			Text:  msg.UserData(),
		}

		if msg.Concat {
			key := multiKey{Peer: sms.Peer, Ref: int(msg.RefID)<<16 | msg.Ref}
			if msg.Part == 1 {
				baseMsg[key] = sms
			}
			parts := append(multiparts[key], msg.userData)
			if len(parts) == msg.NParts {
				delete(multiparts, key)
				sms := baseMsg[key]
				delete(baseMsg, key)
				sms.Text = mergeConcatSMS(parts, msg.Unicode)
				msgs = append(msgs, sms)
			} else {
				multiparts[key] = parts
			}
		} else {
			msgs = append(msgs, sms)
		}
	}
	sort.Sort(smsByDate(msgs))
	return msgs, nil
}

type smsByDate []SMS

func (s smsByDate) Len() int           { return len(s) }
func (s smsByDate) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }
func (s smsByDate) Less(i, j int) bool { return s[i].When.Before(s[j].When) }

func mergeConcatSMS(parts []userData, uni bool) string {
	p := make(map[int]string)
	nparts := 0
	for _, part := range parts {
		p[part.Part] = part.Text(uni)
		nparts = part.NParts
	}
	t := ""
	for i := 1; i <= nparts; i++ {
		t += p[i]
	}
	return t
}

type Image struct {
	NBFFile string
	Type    string
	Stamp   time.Time
	Peer    string
	Data    []byte
}

func (r *Reader) Images() (images []Image, err error) {
	// convenience method to extract JPEG images
	for _, f := range r.z.File {
		if !strings.HasPrefix(f.Name, "predefmessages/") {
			continue
		}
		if f.Mode().IsDir() {
			continue
		}
		base := path.Base(f.Name)
		info, err := parseNBFFilename(base)
		if err != nil {
			log.Printf("invalid entry name %q: %s", base, err)
			continue
		}
		fr, err := f.Open()
		if err != nil {
			log.Printf("cannot read %s: %s", base, err)
			continue
		}
		blob, err := ioutil.ReadAll(fr)
		if err != nil {
			log.Printf("cannot read %s: %s", base, err)
			continue
		}
		count := 0
		for len(blob) > 0 {
			idx := bytes.Index(blob, []byte("\x89PNG\r\n\x1a\n"))
			if idx >= 0 {
				// 12 bytes end marker (00 00 IEND CRC)
				idx2 := bytes.Index(blob[idx:], []byte("\x00\x00\x00\x00IEND"))
				if idx2 < 0 {
					log.Printf("broken PNG image? (in %s)", base)
					break
				}
				img := Image{
					NBFFile: base,
					Type:    "png",
					Stamp:   DosTime(info.Timestamp).Local(),
					Peer:    info.Peer,
					Data:    blob[idx : idx+idx2+12],
				}
				images = append(images, img)
				count++
				blob = blob[idx+idx2:]
				continue
			}
			// look for 0xff 0xd8 ... JFIF ... 0xff 0xd9
			idx = bytes.Index(blob, []byte{0xff, 0xd8})
			if idx < 0 {
				break
			}
			idx1a := bytes.Index(blob[idx:], []byte("JFIF"))
			idx1b := bytes.Index(blob[idx:], []byte("Exif"))
			if idx1a < 0 && idx1b < 0 {
				// no JPEG here
				break
			}

			//log.Printf("analyzing %s at offset %d", base, idx)
			jpg, ok := findJpeg(blob[idx:])
			if ok {
				img := Image{
					NBFFile: base,
					Type:    "jpg",
					Stamp:   DosTime(info.Timestamp).Local(),
					Peer:    info.Peer,
					Data:    jpg,
				}
				if len(jpg) < 1400 {
					log.Printf("skipping thumbnail in %s (size %d)", base, len(jpg))
				} else {
					images = append(images, img)
					count++
				}
				blob = blob[idx+len(jpg):]
			} else {
				blob = blob[idx+2:]
			}
		}
		if count == 0 && f.UncompressedSize64 > 1000 {
			log.Printf("no image found in message of size %d: %s", f.UncompressedSize64, base)
		}
	}
	return
}

func findJpeg(s []byte) (jpg []byte, ok bool) {
	defer func() {
		if p := recover(); p != nil {
			ok = false
		}
	}()
	// A JPEG image is a concatenation of segments of the form
	// (FF)* FF xx l1 l2 <L-2 bytes>
	// where
	//  xx = d8 : start of image
	//  xx = d9 : end of image
	off := 2
	for {
		if s[off] != 0xff {
			log.Printf("not a JPEG image: found %x at offset %d", s[off:off+2], off)
			return nil, false
		}
		for s[off] == 0xff {
			off++
		}
		tag := s[off]
		off++
		switch {
		case tag == 0x00, // escaped 0xff
			0xd0 <= tag && tag <= 0xd7, // restart segment
			tag == 0xda:                // start of scan
			// Not followed by segment length, jump to next 0xff.
			idx := bytes.IndexByte(s[off:], 0xff)
			if idx < 0 {
				return nil, false // there must be a 0xff somewhere
			}
			off += idx
		case tag == 0xd9:
			// End Of Image
			return s[:off], true
		default:
			l1, l2 := s[off], s[off+1]
			length := int(l1)<<8 | int(l2)
			off += length
			if off > len(s) {
				log.Printf("not a JPEG image: length out of bounds %d", length)
				return nil, false
			}
		}
	}
}
