// nbfextract is a utility that dumps contents of a NBF archive
// into mainstream format files.
package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	//"github.com/remyoudompheng/go-misc/nokia/mms"
	"github.com/remyoudompheng/go-misc/nokia/nbf"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s input.nbf destdir/", os.Args[0])
		os.Exit(1)
	}
	input := os.Args[1]
	destdir := os.Args[2]

	log.Printf("dumping %s to %s", input, destdir)
	f, err := nbf.OpenFile(input)
	if err != nil {
		log.Fatalf("could not open %s: %s", input, err)
	}
	defer f.Close()

	inbox, err := f.Inbox()
	if err != nil {
		log.Fatal(err)
	}

	dumpMessage := func(m nbf.SMS, p string) {
		mout, err := os.Create(p)
		if err != nil {
			log.Fatalf("cannot create %s/inbox: %s", destdir, err)
		}
		fmt.Fprintf(mout, "Date: %s\n", m.When.Format("02 Jan 2006 15:04:05 -0700"))
		if m.Type == 0 {
			fmt.Fprintf(mout, "From: %s\n", m.Peer)
		} else {
			for _, p := range m.Peers {
				fmt.Fprintf(mout, "To: %s\n", p)
			}
		}
		fmt.Fprintf(mout, "\n%s\n\n", m.Text)
		err = mout.Close()
		if err != nil {
			log.Fatal(err)
		}
	}
	for i, m := range inbox {
		p := filepath.Join(destdir, m.When.Format("20060102-150405")+
			fmt.Sprintf("-%04d-%s-inbox.msg", i, m.Peer))
		dumpMessage(m, p)
	}

	outbox, err := f.Outbox()
	if err != nil {
		log.Fatal(err)
	}
	for i, m := range outbox {
		if m.Peer == "" && len(m.Peers) > 0 {
			m.Peer = "multiple"
		}
		p := filepath.Join(destdir, m.When.Format("20060102-150405")+
			fmt.Sprintf("-%04d-%s-outbox.msg", i, m.Peer))
		dumpMessage(m, p)
	}

	images, err := f.Images()
	if err != nil {
		log.Fatal("cannot extract images:", err)
	}
	log.Printf("dumping %d images to %s", len(images), destdir)
	for i, img := range images {
		stamp := img.Stamp.Format("20060102-150405")
		out := filepath.Join(destdir, fmt.Sprintf("%s-%s-%03d.%s", stamp, img.Peer, i, img.Type))
		err := ioutil.WriteFile(out, img.Data, 0644)
		if err != nil {
			log.Printf("error writing image to %s: %s", out, err)
		}
	}
}
