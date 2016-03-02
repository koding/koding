package report

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"testing"
	"text/tabwriter"

	"github.com/remyoudompheng/go-misc/pprof/parser"
)

func TestHeapProfile(t *testing.T) {
	f, err := os.Open("testdata/heap.prof")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	p, err := parser.NewHeapProfParser(f)
	if err != nil {
		t.Fatal(err)
	}

	syms := readSymbols("testdata/heap.prof.symbols")
	printed := 0
	for {
		rec, err := p.ReadRecord()
		if err == io.EOF {
			break
		}
		s := stringify(rec.Trace, syms)
		if printed < 10 {
			printed++
			t.Logf("%d:%d [%d:%d] @ %v",
				rec.LiveObj, rec.LiveBytes,
				rec.AllocObj, rec.AllocBytes, s)
		}
	}
}

func TestHeapProfileReport(t *testing.T) {
	f, err := os.Open("testdata/heap.prof")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	p, err := parser.NewHeapProfParser(f)
	if err != nil {
		t.Fatal(err)
	}

	syms := readSymbols("testdata/heap.prof.symbols")
	resolve := func(u uint64) string { s, _ := lookup(u, syms); return s }
	reporter := &Reporter{Resolver: resolve}
	for {
		rec, err := p.ReadRecord()
		if err == io.EOF {
			break
		}
		p.AdjustRecord(&rec, resolve)
		reporter.Add(rec.Trace,
			rec.LiveObj, rec.LiveBytes,
			rec.AllocObj, rec.AllocBytes)
	}
	entries := reporter.ReportByFunc(ColAllocBytes)
	buf := new(bytes.Buffer)
	w := tabwriter.NewWriter(buf, 0, 8, 2, ' ', 0)
	fmt.Fprintf(w, "\nalloc space\tallocs\tin use space\tin use count\tFunction\n")
	const MB = 1 << 20
	for _, e := range entries {
		fmt.Fprintf(w, "%.5g\t%d\t%.3g\t%d\t%s\n",
			e.Self[ColAllocBytes]/MB,
			int64(e.Self[ColAllocObj]),
			e.Self[ColLiveBytes]/MB,
			int64(e.Self[ColLiveObj]), e.Name)
	}
	w.Flush()
	t.Log(buf.String())
}

func BenchmarkHeapProfile(b *testing.B) {
	f, err := os.Open("testdata/__prof")
	if err != nil {
		b.Fatal(err)
	}
	defer f.Close()
	p, err := parser.NewHeapProfParser(f)
	if err != nil {
		b.Fatal(err)
	}
	bsize := int64(0)
	for i := 0; i < b.N; i++ {
		rec, err := p.ReadRecord()
		if err == io.EOF {
			// rewind.
			bsize += tell(f)
			f.Seek(0, 0)
			p, _ = parser.NewHeapProfParser(f)
			continue
		}
		_ = rec
	}
	bsize += tell(f)
	b.SetBytes(bsize / int64(b.N))
}
