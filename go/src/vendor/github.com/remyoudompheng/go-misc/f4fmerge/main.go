package main

import (
	"io"
	"log"
	"os"
	"time"
)

func main() {
	files := os.Args[1:]
	for _, file := range files {
		f, err := os.Open(file)
		if err != nil {
			log.Printf("%s: %s", file, err)
			continue
		}
		for {
			box, err := ReadBox(f)
			if err == io.EOF {
				f.Close()
				break
			}
			if err != nil {
				f.Close()
				log.Printf("%s: %s", file, err)
				break
			}
			log.Printf("%s: box %s (%d bytes)", file, box.Type, len(box.Data))
			handleBox(box)
		}
	}
}

var wroteHdr = false

var timeScale uint32

var afrms []Frame
var vfrms []Frame

func handleBox(box Box) {
	var err error
	switch box.Type {
	default:
		return
	case "abst":
		var binfo BootstrapInfo
		binfo, err = handleBootstrapInfo(box)
		timeScale = binfo.TimeScale
		err = writeFLVHeader(os.Stdout)
	case "mdat":
		frames := handleMovieData(box)
		for _, f := range frames {
			if f.Type == 8 {
				f.Stamp += 2800
				afrms = append(afrms, f)
			} else {
				vfrms = append(vfrms, f)
			}
			switch {
			case len(afrms) == 0, len(vfrms) == 0:
				continue
			case afrms[0].Stamp < vfrms[0].Stamp:
				err = writeFrame(afrms[0])
				afrms = afrms[1:]
			case vfrms[0].Stamp <= afrms[0].Stamp:
				err = writeFrame(vfrms[0])
				vfrms = vfrms[1:]
			}
			if err != nil {
				log.Fatal(err)
			}
		}
	}
	if err != nil {
		log.Printf("error in box %s: %s", box.Type, err)
	}
}

var seenHeader [10]bool

func writeFrame(f Frame) error {
	if f.IsSeqHeader() && !seenHeader[f.Type] {
		seenHeader[f.Type] = true
		log.Printf("skipping %s (%d bytes)", f.Describe(), len(f.Data))
		return nil
	}
	stamp := time.Second * time.Duration(f.Stamp) / time.Duration(timeScale)
	log.Printf("frame at %s: %s (%d bytes)", stamp, f.Describe(), len(f.Data))
	return f.WriteTo(os.Stdout)
}

func writeFLVHeader(w io.Writer) error {
	// See E.2 The FLV Header
	_, err := io.WriteString(w, "FLV\x01")
	if err != nil {
		return err
	}
	_, err = w.Write([]byte{
		1<<2 | 1,   // Audio/Video
		0, 0, 0, 9, // length of header
		0, 0, 0, 0, // PreviousTagSize0 (E.3)
	})
	return err
}
