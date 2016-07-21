package main

import (
	"bufio"
	"flag"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"

	"github.com/remyoudompheng/go-misc/pprof/parser"
	"github.com/remyoudompheng/go-misc/pprof/report"
)

var inuseObj, inuseSpace, allocObj, allocSpace bool

func init() {
	log.SetFlags(log.Lshortfile | log.LstdFlags)
	flag.BoolVar(&inuseObj, "inuse_objects", false, "show objects in use")
	flag.BoolVar(&inuseSpace, "inuse_space", false, "show objects in use")
	flag.BoolVar(&allocObj, "alloc_objects", false, "show objects allocated")
	flag.BoolVar(&allocSpace, "alloc_space", false, "show bytes allocated")
}

func LoadSymbols(exe string) (*report.Reporter, error) {
	reporter := new(report.Reporter)
	err := reporter.SetExecutable(exe)
	return reporter, err
}

func LoadProfile(r *report.Reporter, f io.ReadCloser) {
	defer f.Close()
	buf := bufio.NewReader(f)
	magic, _ := buf.Peek(4)
	switch string(magic) {
	case "heap":
		// Heap profile.
		p, err := parser.NewHeapProfParser(buf)
		if err != nil {
			log.Fatal(err)
		}
		for {
			rec, err := p.ReadRecord()
			if err == io.EOF {
				break
			}
			p.AdjustRecord(&rec,
				func(uint64) string { return "" })
			r.Add(rec.Trace,
				rec.LiveObj, rec.LiveBytes,
				rec.AllocObj, rec.AllocBytes)
		}
	default:
		// CPU Profile.
		p, err := parser.NewCpuProfParser(buf)
		if err != nil {
			log.Fatal(err)
		}
		for {
			trace, count, err := p.ReadTrace()
			if trace == nil && err == io.EOF {
				break
			}
			r.Add(trace, int64(count))
		}
	}
}

func PrintGraph(w io.Writer, r *report.Reporter, exe string) {
	col := report.ColCPU
	switch {
	case allocObj:
		col = report.ColAllocObj
	case allocSpace:
		col = report.ColAllocBytes
	case inuseObj:
		col = report.ColLiveObj
	case inuseSpace:
		col = report.ColLiveBytes
	}
	g := r.GraphByFunc(col)
	report := report.GraphReport{
		Prog:  exe,
		Total: r.Total(col),
		Unit:  "samples",
		Graph: g,

		NodeFrac: .005,
		EdgeFrac: .001,
	}
	report.WriteTo(w)
}

func main() {
	flag.Parse()
	args := flag.Args()
	if len(args) == 1 {
		// pprof http://...
		r := new(report.Reporter)
		u := args[0]
		resp, err := http.Get(u)
		if err != nil {
			log.Fatal(err)
		}
		LoadProfile(r, resp.Body)
		symu, err := url.Parse(u)
		if err != nil {
			log.Fatal(err)
		}
		symu.Path = "/debug/pprof/symbol"
		table := &report.RemoteResolver{Url: symu.String()}
		err = table.Prepare(r.Symbols())
		if err != nil {
			log.Fatal(err)
		}
		r.Resolver = table
		PrintGraph(os.Stdout, r, u)
	} else {
		exe, prof := args[0], args[1]
		r, err := LoadSymbols(exe)
		if err != nil {
			log.Fatal(err)
		}
		f, err := os.Open(prof)
		if err != nil {
			log.Fatal(err)
		}
		LoadProfile(r, f)
		PrintGraph(os.Stdout, r, exe)
	}
}
