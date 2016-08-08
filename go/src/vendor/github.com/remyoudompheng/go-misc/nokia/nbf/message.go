package nbf

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"strconv"
	"time"
	"unicode/utf16"
)

// predefmessages/1: inbox
// predefmessages/3: outbox

type msgInfo struct {
	// Filename information
	Seq          uint32
	Timestamp    uint32
	MultipartSeq uint16
	Flags        uint16
	PartNo       uint8
	PartTotal    uint8
	Peer         string
}

// ParseFilename decomposes the filename of messages found in NBF archives.
// 00001DFC: sequence number of message
// 3CEAC364: Dos timestamp (seconds since 01 Jan 1980, 32-bit integer)
// 00B7: 16-bit multipart sequence number (identical for parts of the same message)
// 2010: 1st byte 0x20 for sms, 0x10 for mms
// 00500000:
// 00302000: for multipart: 2 out of 3.
// 00000000: zero
// 00000000: zero
// 000000000: zero (9 digits)
// 36300XXXXXXX : 12 digit number (7 digit in old format)
// 0000007C : a checksum ?
func parseNBFFilename(filename string) (inf msgInfo, err error) {
	s := filename
	if len(s) < 80 {
		return inf, fmt.Errorf("too short")
	}
	s, inf.Seq, err = getUint32(s)
	if err != nil {
		return
	}
	s, inf.Timestamp, err = getUint32(s)
	if err != nil {
		return
	}
	s, n, err := getUint32(s)
	if err != nil {
		return
	}
	inf.MultipartSeq = uint16(n >> 16)
	inf.Flags = uint16(n)
	s = s[8:] // skip
	s, n, err = getUint32(s)
	if err != nil {
		return
	}
	inf.PartNo = uint8(n >> 12)
	inf.PartTotal = uint8(n >> 20)
	s = s[25:] // skip
	if len(s) == 12+8 {
		inf.Peer = string(s[:12])
	} else {
		inf.Peer = string(s[:7])
	}
	return inf, nil
}

func getUint32(s string) (rest string, n uint32, err error) {
	x, err := strconv.ParseUint(s[:8], 16, 32)
	return s[8:], uint32(x), err
}

const (
	FLAGS_SMS = 0x2000
	FLAGS_MMS = 0x1000
)

func DosTime(stamp uint32) time.Time {
	t := time.Unix(int64(stamp), 0)
	// Add 10 years
	t = t.Add(3652 * 24 * time.Hour)
	return t
}

// A big-endian interpretation of the binary format.
type rawMessage struct {
	Filename string // DEBUG

	Peer  string
	Text  string
	Peers []string
	// From PDU
	Msg message
}

type message interface {
	UserData() string
}

// SMS encoding.
// Inspired by libgammu's libgammu/phone/nokia/dct4s40/6510/6510file.c

// Structure: all integers are big-endian
// u16 u16 u32 u32(size)
// [82]byte (zero)
// [41]uint16 (NUL-terminated peer name)
// PDU (offset is 0xb0)
// 65 unknown bytes
// 0001 0003 size(uint16) [size/2]uint16 (NUL-terminated text)
// 02 size(uint16) + NUL-terminated [size]byte (SMS center)
// 04 0001 002b size(uint16) + [size]byte (NUL-terminated UTF16BE) (peer)
// [23]byte unknown data

func parseMessage(s []byte) (m rawMessage, err error) {
	// peer (fixed offset 0x5e)
	var runes []uint16
	for off := 0x5e; s[off]|s[off+1] != 0; off += 2 {
		runes = append(runes, binary.BigEndian.Uint16(s[off:off+2]))
	}
	peer := string(utf16.Decode(runes))

	// PDU frame starts at 0xb0
	// incoming PDU frame:
	// * NN 91 <NN/2 bytes> (NN : number of BCD digits, little endian)
	//   source number, padded with 0xf halfbyte.
	// * 00 FF (data format, GSM 03.40 section 9.2.3.10)
	// * YY MM DD HH MM SS ZZ (BCD date time, little endian)
	// * NN <NN septets> (NN : number of packed 7-bit data)
	// received SMS: 04 0b 91
	pdu := s[0xb0:]
	msgType := pdu[0]
	if msgType == 0x8c {
		err = fmt.Errorf("MMS is not supported")
		return
	}
	var msg message
	switch msgType & 3 {
	case 0: // SMS-DELIVER
		var n int
		var err error
		msg, n, err = parseDeliverMessage(pdu)
		if err != nil {
			return rawMessage{}, err
		}
		pdu = pdu[n:]
	case 1: // SMS-SUBMIT
		var n int
		var err error
		msg, n, err = parseSubmitMessage(pdu)
		if err != nil {
			return rawMessage{}, err
		}
		pdu = pdu[n:]
	case 2: // SMS-COMMAND
		return rawMessage{}, fmt.Errorf("unsupported message type SMS-COMMAND")
	case 3: // reserved
		panic("invalid message type 3")
	}
	// END of PDU.
	if len(pdu) == 0 {
		return rawMessage{Peer: peer, Msg: msg}, nil
	}
	if len(pdu) < 72 {
		return rawMessage{}, fmt.Errorf("truncated message")
	}
	pdu = pdu[65:]
	length := int(pdu[5])
	pdu = pdu[6:]
	text := make([]rune, length/2)
	for i := range text {
		text[i] = rune(binary.BigEndian.Uint16(pdu[2*i : 2*i+2]))
	}

	m = rawMessage{
		Peer: peer,
		Text: string(text),
		Msg:  msg,
	}

	// peers at the end.
	if msgType&3 == 0 {
		return m, nil
	}
	data := pdu[length:]
	getStringAfter := func(pattern []byte) string {
		idx := bytes.Index(data, pattern)
		if idx < 0 {
			return ""
		}
		length := binary.BigEndian.Uint16(data[idx+len(pattern):]) / 2
		s := data[idx+len(pattern)+2:]
		text := make([]rune, length)
		for i := 0; i < int(length); i++ {
			text[i] = rune(binary.BigEndian.Uint16(s[2*i : 2*i+2]))
		}
		data = s[2*length:]
		if len(text) > 0 && text[len(text)-1] == 0 {
			text = text[:len(text)-1]
		}
		return string(text)
	}
	idx := 0
	for len(data) > 0 {
		number := getStringAfter([]byte{4, 0, 1, byte(idx), 0x2b})
		if number == "" {
			break
		}
		name := getStringAfter([]byte{0x2c})
		m.Peers = append(m.Peers, fmt.Sprintf("%s <%s>", number, name))
		idx++
	}

	return m, nil
}

// Parsing of DELIVER-MESSAGE

// A deliverMessage represents the contents of a SMS-DELIVER message
// as per GSM 03.40 TPDU specification.
type deliverMessage struct {
	MsgType  byte
	MoreMsg  bool // true encoded as zero
	FromAddr string
	Protocol byte
	// Coding byte
	Compressed bool
	Unicode    bool
	SMSCStamp  time.Time

	userData
}

type userData struct {
	RawData []byte // UCS-2 encoded text, unpacked 7-bit data.

	// Concatenated SMS
	Concat            bool
	Ref, Part, NParts int

	SingleShift byte
}

func (msg userData) Text(uni bool) string {
	if uni {
		runes := make([]uint16, len(msg.RawData)/2)
		for i := range runes {
			hi, lo := msg.RawData[2*i], msg.RawData[2*i+1]
			runes[i] = uint16(hi)<<8 | uint16(lo)
		}
		return string(utf16.Decode(runes))
	} else {
		if msg.SingleShift > 0 && msg.RawData[0] == 0x1b {
			// FIXME: actually implement single shift table.
			return translateSMS(msg.RawData[1:], &basicSMSset)
		}
		return translateSMS(msg.RawData, &basicSMSset)
	}
}

func (msg deliverMessage) UserData() string {
	return msg.userData.Text(msg.Unicode)
}

func parseDeliverMessage(s []byte) (msg deliverMessage, size int, err error) {
	p := s
	msg.MsgType = p[0] & 3    // TP-MTI
	msg.MoreMsg = p[0]&4 == 0 // TP-MMS
	hasUDH := p[0]&0x40 != 0  // TP-UDHI
	addrLen := int(p[1])
	msg.FromAddr, err = parseAddress(p[1 : 3+(addrLen+1)/2])
	if err != nil {
		return
	}
	size += 3 + (addrLen+1)/2
	p = s[size:]

	// Format
	format := p[1]
	msg.Compressed = format&0x20 != 0
	msg.Unicode = format&8 != 0

	// Date time
	msg.SMSCStamp = parseDateTime(p[2:9])
	size += 2 + 7
	p = s[size:]

	// Payload
	var udsize int
	msg.userData, udsize = parseUserData(p, msg.Unicode, hasUDH)
	size += udsize
	return
}

// A submitMessage represents the contents of a SMS-DELIVER message
// as per GSM 03.40 TPDU specification.
type submitMessage struct {
	MsgType  byte
	RefID    byte
	ToAddr   string
	Protocol byte
	// Coding byte
	Compressed bool
	Unicode    bool

	userData
}

func (msg submitMessage) UserData() string {
	return msg.userData.Text(msg.Unicode)
}

func parseSubmitMessage(s []byte) (msg submitMessage, size int, err error) {
	p := s
	msg.MsgType = p[0] & 3 // TP-MTI
	hasVP := p[0] >> 2 & 3
	hasUDH := p[0]&0x40 != 0 // TP-UDHI
	msg.RefID = p[1]
	addrLen := int(p[2])
	msg.ToAddr, err = parseAddress(p[2 : 4+(addrLen+1)/2])
	if err != nil {
		return
	}
	size += 4 + (addrLen+1)/2
	p = s[size:]

	// Format
	format := p[1]
	msg.Compressed = format&0x20 != 0
	msg.Unicode = format&8 != 0

	// Validity Period
	if hasVP != 0 {
		panic("validity period not implemented")
	}
	size += 2 + 1 // unknown 0xff byte
	p = s[size:]

	// Payload
	var udsize int
	msg.userData, udsize = parseUserData(p, msg.Unicode, hasUDH)
	size += udsize
	return
}

func parseUserData(p []byte, uni, udh bool) (msg userData, size int) {
	if uni {
		// Unicode (70 UCS-2 characters in 140 bytes)
		length := int(p[0]) // length in bytes
		msg.RawData = p[1 : length+1]
		size += length + 1
	} else {
		// 7-bit encoded format (160 septets in 140 bytes)
		length := int(p[0]) // length in septets
		packedLen := length - length/8
		msg.RawData = unpack7bit(p[1 : 1+packedLen])
		msg.RawData = msg.RawData[:length]
		size += packedLen + 1
	}
	ud := p[1:]
	switch {
	case len(ud) >= 6 && ud[0] == 5 && ud[1] == 0 && ud[2] == 3:
		// Concatenated SMS data starts with 0x05 0x00 0x03 Ref NPart Part
		msg.Concat = true
		msg.Part = int(ud[5])
		msg.NParts = int(ud[4])
		msg.Ref = int(ud[3])
	case len(ud) >= 7 && ud[0] == 6 && ud[1] == 8 && ud[2] == 4:
		// Concatenated SMS data with 16-bit ref number.
		msg.Concat = true
		msg.Part = int(ud[6])
		msg.NParts = int(ud[5])
		msg.Ref = int(ud[3])<<8 | int(ud[4])
	}
	// TODO: parse other UDH fields
	// http://en.wikipedia.org/wiki/User_Data_Header
	if udh {
		udhLength := ud[0] + 1
		if ud[1] == 0x24 {
			// single shift table
			msg.SingleShift = ud[3]
		}
		if uni {
			msg.RawData = msg.RawData[udhLength:]
		} else {
			n := (8*udhLength + 6) / 7 // n such that 7*n >= udhLength*8
			msg.RawData = msg.RawData[n:]
		}
	}
	return
}

func parseAddress(b []byte) (string, error) {
	length := int(b[0])
	typ := b[1]
	switch (typ >> 4) & 7 {
	case 1: // international
		num := decodeBCD(b[2:])
		if len(num) < length {
			return "", fmt.Errorf("BUG: num=%q when parsing %x", num, b)
		}
		return "+" + num[:length], nil
	case 0, 2: // unknown, national
		num := decodeBCD(b[2:])
		return num[:length], nil
	case 5: // alphanumeric
		addr7 := unpack7bit(b[2:])
		return translateSMS(addr7, &basicSMSset), nil
	default:
		return "", fmt.Errorf("unsupported address format: 0x%02x", typ)
	}
}

// Ref: GSM 03.40 section 9.2.3.11
func parseDateTime(b []byte) time.Time {
	var dt [7]int
	for i := range dt {
		dt[i] = int(b[i]&0xf)*10 + int(b[i]>>4)
	}
	return time.Date(
		2000+dt[0],
		time.Month(dt[1]),
		dt[2],
		dt[3], dt[4], dt[5], 0, time.FixedZone("", dt[6]*3600/4))
}

func decodeBCD(b []byte) string {
	s := make([]byte, 0, len(b)*2)
	for _, c := range b {
		s = append(s, '0'+(c&0xf))
		if c>>4 == 0xf {
			break
		} else {
			s = append(s, '0'+(c>>4))
		}
	}
	return string(s)
}

func unpack7bit(s []byte) []byte {
	// each byte may contain a part of septet i in lower bits
	// and septet i+1 in higher bits.
	buf := uint16(0)
	buflen := uint(0)
	out := make([]byte, 0, len(s)+len(s)/7+1)
	for len(s) > 0 {
		buf |= uint16(s[0]) << buflen
		buflen += 8
		s = s[1:]
		for buflen >= 7 {
			out = append(out, byte(buf&0x7f))
			buflen -= 7
			buf >>= 7
		}
	}
	return out
}

// translateSMS decodes a 7-bit encoded SMS text into a standard
// UTF-8 encoded string.
func translateSMS(s []byte, charset *[256]rune) string {
	r := make([]rune, 0, len(s))
	esc := byte(0)
	for _, b := range s {
		if charset[b] == -1 { // escape
			esc = 128
		} else {
			r = append(r, charset[esc|b])
			esc = 0
		}
	}
	return string(r)
}

// See http://en.wikipedia.org/wiki/GSM_03.38

var basicSMSset = [256]rune{
	// 0x00
	'@', '£', '$', '¥', 'è', 'é', 'ù', 'ì',
	'ò', 'Ç', '\n', 'Ø', 'ø', '\r', 'Å', 'å',
	// 0x10
	'Δ', '_', 'Φ', 'Γ', 'Λ', 'Ω', 'Π', 'Ψ',
	'Σ', 'Θ', 'Ξ', -1 /* ESC */, 'Æ', 'æ', 'ß', 'É',
	// 0x20
	' ', '!', '"', '#', '¤', '%', '&', '\'',
	'(', ')', '*', '+', ',', '-', '.', '/',
	// 0x30
	'0', '1', '2', '3', '4', '5', '6', '7',
	'8', '9', ':', ';', '<', '=', '>', '?',
	// 0x40
	'¡', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
	'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
	// 0x50
	'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
	'X', 'Y', 'Z', 'Ä', 'Ö', 'Ñ', 'Ü', '§',
	// 0x60
	'¿', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
	'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
	// 0x70
	'p', 'q', 'r', 's', 't', 'u', 'v', 'w',
	'x', 'y', 'z', 'ä', 'ö', 'ñ', 'ü', 'à',
	// Extensions
	0x8A: '\f',
	0x94: '^',
	0xA8: '{', 0xA9: '}', 0xAF: '\\',
	0xBC: '[', 0xBD: '~', 0xBE: ']',
	0xC0: '|',
	0xE5: '€',
}
