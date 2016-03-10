package main

import (
	"bytes"
	"image"
	"image/jpeg"
	"io/ioutil"
	"os"
	"os/exec"
	"testing"
	"time"
)

func TestEmptyPdf(t *testing.T) {
	p := startPDF(t)
	defer endPDF(t, p)

	p.WriteInfo("test document", time.Now())
	p.WritePage(21*CM, 29.7*CM,
		[]byte("q\n173.52 0 0 245.76 0 0 cm\nQ\n"))
}

func TestSimplePdf(t *testing.T) {
	var size image.Rectangle
	size.Max.X, size.Max.Y = 1200, 1800

	img := image.NewRGBA(size)
	for i := range img.Pix {
		x := i / img.Stride
		y := i % img.Stride
		img.Pix[i] = byte((x + y) / 16)
	}
	buf := new(bytes.Buffer)
	err := jpeg.Encode(buf, img, &jpeg.Options{Quality: 85})
	if err != nil {
		t.Fatal(err)
	}

	p := startPDF(t)
	defer endPDF(t, p)

	p.WriteInfo("test document with image", time.Now())
	p.WriteJPEGPage(img, buf.Bytes())
}

func startPDF(t *testing.T) *PDFWriter {
	f, err := ioutil.TempFile("", "pdftest")
	if err != nil {
		t.Fatal(err)
	}
	p, err := NewPDFWriter(f)
	if err != nil {
		t.Fatal(err)
	}
	return p
}

func endPDF(t *testing.T, p *PDFWriter) {
	f := p.w.(*os.File)
	//t.Log(f.Name())
	defer os.Remove(f.Name())
	p.Flush()
	if p.err != nil {
		t.Fatal(p.err)
	}
	err := f.Close()
	if err != nil {
		t.Fatal(err)
	}
	out, err := exec.Command("pdfinfo", f.Name()).CombinedOutput()
	t.Logf("%s", out)
	if err != nil {
		t.Error(err)
	}
}
