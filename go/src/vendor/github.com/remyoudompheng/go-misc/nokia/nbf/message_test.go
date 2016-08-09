package nbf

import (
	"testing"
)

func TestMessage_ParseFilename(t *testing.T) {
	const name = "0000186F3C52A89B0042201000500000004030000000000000000000000000000+336345632330000009F"
	msg, err := parseNBFFilename(name)
	if err != nil {
		t.Fatal(err)
	}

	if msg.Seq != 0x186f {
		t.Errorf("bad sequence number: 0x%x", msg.Seq)
	}
	if msg.Timestamp != 0x3c52a89b {
		t.Errorf("bad timestamp: 0x%x", msg.Timestamp)
	}
	t.Logf("timestamp: %s", DosTime(msg.Timestamp))
	if msg.MultipartSeq != 0x42 {
		t.Errorf("bad multipart sequence number: %d", msg.MultipartSeq)
	}
	if msg.Flags != 0x2010 {
		t.Errorf("bad flags: 0x%x", msg.Flags)
	}
	if msg.PartNo != 3 || msg.PartTotal != 4 {
		t.Errorf("got part %d/%d, expected 3/4",
			msg.PartNo, msg.PartTotal)
	}
	if msg.Peer != "+33634563233" {
		t.Errorf("wrong peer %s, expected +33634563233", msg.Peer)
	}
}

func TestDecode7bit(t *testing.T) {
	var data = []byte{0xd2, 0xf7, 0xfb, 0xfd, 0x7e, 0x83, 0xe8, 0x75, 0x90, 0xbd, 0x5c, 0xc7, 0x83,
		0xe2, 0xf5, 0x32, 0x48, 0x7d, 0x0a, 0xc3, 0xe1, 0x65, 0x36, 0xbb, 0xfc, 0x3}
	u := unpack7bit(data)
	t.Logf("in: %d bytes, out: %d septets", len(data), len(u))
	s := translateSMS(unpack7bit(data), &basicSMSset)
	const ref = "Rooooo tu veux que j'appelle?"
	if s != ref {
		t.Errorf("got %q, expected %q", s, ref)
	}
	t.Logf("%s", s)

	data = []byte{0x9b, 0xd7, 0xfb, 0x05} // 1b 2f 6f 2f
	s = translateSMS(unpack7bit(data), &basicSMSset)
	if s != `\o/` {
		t.Errorf(`got %q, expected \o/`, s)
	}
}

func TestParseAddr(t *testing.T) {
	// Examples from Wikipedia: http://en.wikipedia.org/wiki/GSM_03.40#Addresses
	a, err := parseAddress([]byte("\x0B\x91\x51\x55\x21\x43\x65\xF7"))
	if err != nil {
		t.Fatal(err)
	}
	if a != "+15551234567" {
		t.Errorf("got %q, expected +15551234567", a)
	}
	a, err = parseAddress([]byte("\x14\xD0\xC4\xF2\x3C\x7D\x76\x03\x90\xEF\x76\x19"))
	if err != nil {
		t.Fatal(err)
	}
	if a != "Design@Home" {
		t.Errorf("got %q, expected Design@home", a)
	}
	a, err = parseAddress([]byte("\x03\x85\x16\xf8"))
	if err != nil {
		t.Fatal(err)
	}
	if a != "618" {
		t.Errorf("got %q, expected 618", a)
	}
}
