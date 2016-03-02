package nbu

import (
	"flag"
	"io"
	"strings"
	"testing"
)

func TestReadTime(t *testing.T) {
	var input = "\x61\x18\xce\x01\x40\xde\x71\x9e"
	tm, err := readTime(strings.NewReader(input))
	if err != nil {
		t.Fatal(err)
	}
	if tm.String() != "2013-03-03 22:51:18.948 +0000 UTC" {
		t.Errorf("got %s, expected %s", tm,
			"2013-03-03 22:51:18.948 +0000 UTC")
	}
}

func TestReadString(t *testing.T) {
	var input = "\x05\x00C\x003\x00-\x000\x000\x00"
	s, err := readString(strings.NewReader(input))
	if err != nil {
		t.Fatal(err)
	}
	if s != "C3-00" {
		t.Errorf("got %q, expected %q", s, "C3-00")
	}
}

var path = flag.String("input", "", "input file for testing")

func TestFile(t *testing.T) {
	if *path == "" {
		t.Logf("skipping since no input file specified")
		return
	}
	r, err := OpenFile(*path)
	if err != nil {
		t.Fatal(err)
	}
	info, err := r.Info()
	if err != nil {
		t.Error(err)
	}
	sects := info.Sections
	info.Sections = nil
	t.Logf("%+v", info)
	for _, sec := range sects {
		t.Logf("%s: %+v", secNames[sec.Type], sec)
	}

	// Test messages.
	for _, sec := range sects {
		if sec.Type == SecMessages {
			for id, off := range sec.Folders {
				r := io.NewSectionReader(r.File, off, sec.Offset+16+sec.Length-off)
				title, msgs, err := parseMessageFolder(r)
				if err != nil {
					t.Error(err)
				}
				t.Logf("Folder %d %q", id, title)
				t.Logf("%d messages", len(msgs))
				if len(msgs) > 0 {
					t.Logf("First message: %s", msgs[0])
					t.Logf("Last message: %s", msgs[len(msgs)-1])
				}
			}
		}
		if sec.Type == SecMMS {
			for id, off := range sec.Folders {
				r := io.NewSectionReader(r.File, off, sec.Offset+16+sec.Length-off)
				title, msgs, err := parseMMSFolder(r)
				if err != nil {
					t.Error(err)
				}
				t.Logf("Folder %d %q", id, title)
				t.Logf("%d messages", len(msgs))
				if len(msgs) > 0 {
					first, last := msgs[0], msgs[len(msgs)-1]
					t.Logf("First message: %q...%q", first[:40], first[len(first)-40:])
					t.Logf("Last message: %q...%q", last[:40], last[len(last)-40:])
				}
			}
		}
	}
}
