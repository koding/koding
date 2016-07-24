package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/remyoudompheng/go-misc/debug/ar"
	"github.com/remyoudompheng/go-misc/debug/go5"
	"github.com/remyoudompheng/go-misc/debug/go6"
	"github.com/remyoudompheng/go-misc/debug/go8"
	"github.com/remyoudompheng/go-misc/debug/goobj"
)

var (
	fullpath bool
	showpc   bool
)

var cwd, _ = os.Getwd()

func cleanPath(s *string) {
	if fullpath {
		rel, err := filepath.Rel(cwd, *s)
		if err == nil && len(rel) < len(*s) {
			*s = rel
		}
	} else {
		*s = filepath.Base(*s)
	}
}

func main() {
	flag.BoolVar(&fullpath, "fullpath", false, "show full file names")
	flag.BoolVar(&showpc, "pc", false, "show instruction numbering")
	flag.Parse()
	obj := flag.Arg(0)
	f, err := os.Open(obj)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	rd := bufio.NewReader(f)

	// Read first line.
	line, err := rd.Peek(8)
	if err != nil {
		log.Fatal(err)
	}
	switch string(line) {
	case "!<arch>\n":
		dumparchive(rd)
	case "go objec":
		dumpobj(rd)
	default:
		log.Fatalf("unknown file type %s: bad magic %q", obj, line)
	}
}

func dumpobj(rd *bufio.Reader) {
	first := true
	gochar := byte(0)
	ver := goobj.GO1_1
	for {
		line, err := rd.ReadSlice('\n')
		if err != nil && err != bufio.ErrBufferFull {
			log.Fatal(err)
		}
		if len(line) == 2 && string(line) == "!\n" {
			break
		}
		if first {
			first = false
			// go object GOOS GOARCH VERSION
			words := strings.Fields(string(line))
			arch := words[3]
			switch arch {
			case "arm":
				gochar = '5'
			case "amd64":
				gochar = '6'
			case "386":
				gochar = '8'
			default:
				log.Printf("unrecognized object format %q", line)
				return
			}
			version := words[4]
			switch version {
			case "go1", "go1.0.1", "go1.0.2", "go1.0.3":
				ver = goobj.GO1
			}
		}
	}

	switch gochar {
	case '5':
		r5 := go5.NewReader(rd)
		r5.Version = ver
		dump(Reader5{r5})
	case '6':
		r6 := go6.NewReader(rd)
		r6.Version = ver
		dump(Reader6{r6})
	case '8':
		r8 := go8.NewReader(rd)
		r8.Version = ver
		dump(Reader8{r8})
	}
}

func dumparchive(rd *bufio.Reader) {
	r := ar.NewReader(rd)
	for {
		hdr, err := r.Next()
		switch err {
		case nil:
		case io.EOF:
			return
		default:
			log.Fatal(err)
		}
		switch hdr.Name {
		case "__.PKGDEF", "__.SYMDEF", "__.GOSYMDEF":
			continue
		default:
			fmt.Printf("--- object %s ---\n", hdr.Name)
			dumpobj(bufio.NewReader(r))
		}
	}
}

func dump(r ProgReader) {
	for {
		p, err := r.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		pc, pos := p.PC(), p.Position()
		cleanPath(&pos.Filename)
		switch p.Opname() {
		case "NAME", "HISTORY":
			// don't print.
			//fmt.Printf("%s\n", p)
		case "TEXT":
			fmt.Println()
			var sym string
			switch prog := p.(type) {
			case go5.Prog:
				sym = prog.From.Sym
			case go6.Prog:
				sym = prog.From.Sym
			case go8.Prog:
				sym = prog.From.Sym
			}
			fmt.Printf("--- prog list %s ---\n", sym)
			fallthrough
		default:
			if showpc {
				fmt.Printf("%04d (%s) %s\n", pc, pos, p)
			} else {
				fmt.Printf("(%s) %s\n", pos, p)
			}
		case "END":
			break
		}
	}

	fset, imports := r.Files()
	fmt.Println("--- imports ---")
	for pos, imp := range imports {
		pos := fset.Position(pos)
		cleanPath(&pos.Filename)
		fmt.Printf("%s: imports %s\n", pos, imp)
	}
}

type Prog interface {
	PC() int
	Opname() string
	Position() goobj.Position
}

type ProgReader interface {
	Read() (Prog, error)
	Files() (*goobj.FileSet, map[int]string)
}

type Reader5 struct{ *go5.Reader }
type Reader6 struct{ *go6.Reader }
type Reader8 struct{ *go8.Reader }

func (r Reader5) Read() (Prog, error) { return r.Reader.ReadProg() }
func (r Reader6) Read() (Prog, error) { return r.Reader.ReadProg() }
func (r Reader8) Read() (Prog, error) { return r.Reader.ReadProg() }
