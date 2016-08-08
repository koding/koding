// nbuextract is a utility that dumps contents of a NBU archive
// into mainstream format files.
package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	"github.com/remyoudompheng/go-misc/nokia/mms"
	"github.com/remyoudompheng/go-misc/nokia/nbu"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s input.nbu destdir/", os.Args[0])
		os.Exit(1)
	}
	input := os.Args[1]
	destdir := os.Args[2]

	log.Printf("dumping %s to %s", input, destdir)
	f, err := nbu.OpenFile(input)
	if err != nil {
		log.Fatalf("could not open %s: %s", input, err)
	}
	defer f.Close()

	// Basic information.
	info, err := f.Info()
	if err != nil {
		log.Fatalf("could not read NBU table of contents: %s", err)
	}

	log.Printf("Device: %s %s (%s — %s)", info.Name, info.Model,
		info.Firmware, info.Language)
	log.Printf("IMEI: %s", info.IMEI)
	log.Printf("Backup time: %s", info.BackupTime)

	for _, sec := range info.Sections {
		switch sec.Type {
		case nbu.SecMessages:
			// Dump SMS
			for _, off := range sec.Folders {
				DumpSMSFolder(f, off, destdir)
			}
		case nbu.SecMMS:
			// Dump MMS
			for _, off := range sec.Folders {
				DumpMMSFolder(f, off, destdir)
			}
		}
	}
}

func DumpSMSFolder(f *nbu.Reader, off int64, destdir string) {
	title, msgs, err := f.ReadMessageFolderAt(off)
	if err != nil {
		log.Printf("could not parse message folder at offset 0x%x: %s", off, err)
		return
	}
	dir := filepath.Join(destdir, "sms", title)
	err = os.MkdirAll(dir, 0755)
	if err != nil {
		log.Fatalf("could not create directory %s: %s", dir, err)
	}

	log.Printf("writing %d SMS to %s", len(msgs), dir)
	for i, msg := range msgs {
		base := fmt.Sprintf("%06d.vmsg", i+1)
		err := ioutil.WriteFile(filepath.Join(dir, base), []byte(msg), 0644)
		if err != nil {
			log.Printf("could not write %s: %s", base, err)
		}
	}
}

func DumpMMSFolder(f *nbu.Reader, off int64, destdir string) {
	title, msgs, err := f.ReadMMSFolderAt(off)
	if err != nil {
		log.Printf("could not parse MMS folder at offset 0x%x: %s", off, err)
		return
	}
	dir := filepath.Join(destdir, "mms", title)
	err = os.MkdirAll(dir, 0755)
	if err != nil {
		log.Fatalf("could not create directory %s: %s", dir, err)
	}

	log.Printf("writing %d MMS to %s", len(msgs), dir)
	for i, msg := range msgs {
		base := fmt.Sprintf("%06d.mms", i+1)
		err := ioutil.WriteFile(filepath.Join(dir, base), msg, 0644)
		if err != nil {
			log.Printf("could not write %s: %s", base, err)
		}
		// try parsing.
		buf := bytes.NewBuffer(msg)
		m, err := mms.ReadMMS(buf)
		log.Printf("err=%s", err)
		log.Printf("%+v", m)
	}
}
