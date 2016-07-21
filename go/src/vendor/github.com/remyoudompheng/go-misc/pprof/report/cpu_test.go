package report

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"testing"
	"text/tabwriter"

	"github.com/remyoudompheng/go-misc/pprof/parser"
)

type symbol struct {
	Addr uint64
	Name string
}

func lookup(addr uint64, syms []symbol) (name string, off int) {
	min, max := 0, len(syms)
	for max-min > 1 {
		med := (min + max) / 2
		a := syms[med].Addr
		if a < addr {
			min = med
		} else {
			max = med
		}
	}
	if syms[min].Addr > addr {
		return "N/A", int(addr)
	}
	return syms[min].Name, int(addr - syms[min].Addr)
}

func readSymbols(name string) []symbol {
	s, err := ioutil.ReadFile(name)
	if err != nil {
		panic(err)
	}
	var syms []symbol
	for _, line := range strings.Split(string(s), "\n") {
		words := strings.Fields(line)
		if len(words) != 3 {
			continue
		}
		addr, sym := words[0], words[2]
		a, err := strconv.ParseUint(addr, 16, 64)
		if err != nil {
			panic(err)
		}
		syms = append(syms, symbol{Addr: a, Name: sym})
	}
	return syms
}

func stringify(addrs []uint64, syms []symbol) string {
	buf := new(bytes.Buffer)
	for i, a := range addrs {
		n, _ := lookup(a, syms)
		if i > 0 {
			buf.WriteByte(' ')
		}
		buf.WriteString(n)
	}
	return buf.String()
}

func TestCpuProfile(t *testing.T) {
	f, err := os.Open("testdata/cpu.prof")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	p, err := parser.NewCpuProfParser(f)
	if err != nil {
		t.Fatal(err)
	}

	syms := readSymbols("testdata/cpu.prof.symbols")
	printed := 0
	for {
		trace, count, err := p.ReadTrace()
		if trace == nil && err == io.EOF {
			break
		}
		s := stringify(trace, syms)
		if printed < 10 {
			printed++
			t.Logf("%d× %v", count, s)
		}
	}
}

func TestCpuProfileReport(t *testing.T) {
	syms := readSymbols("testdata/cpu.prof.symbols")
	resolve := func(u uint64) string { s, _ := lookup(u, syms); return s }

	f, err := os.Open("testdata/cpu.prof")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	p, err := parser.NewCpuProfParser(f)
	if err != nil {
		t.Fatal(err)
	}
	reporter := &Reporter{Resolver: resolve}
	for {
		trace, count, err := p.ReadTrace()
		if trace == nil && err == io.EOF {
			break
		}
		reporter.Add(trace, int64(count))
	}
	entries := reporter.ReportByFunc(ColCPU)
	buf := new(bytes.Buffer)
	w := tabwriter.NewWriter(buf, 0, 8, 2, ' ', 0)
	fmt.Fprintf(w, "\nSelf\tCumul\tName\n")
	for _, e := range entries {
		fmt.Fprintf(w, "%.3g\t%.3g\t%s\n", e.Self[ColCPU], e.Cumul[ColCPU], e.Name)
	}
	w.Flush()
	t.Log(buf.String())
}

func tell(f *os.File) int64 {
	off, err := f.Seek(0, 1)
	if err != nil {
		panic(err)
	}
	return off
}

func BenchmarkCpuProfile(b *testing.B) {
	f, err := os.Open("testdata/cpu.prof")
	if err != nil {
		b.Fatal(err)
	}
	defer f.Close()
	p, err := parser.NewCpuProfParser(f)
	if err != nil {
		b.Fatal(err)
	}
	bsize := int64(0)
	for i := 0; i < b.N; i++ {
		trace, count, err := p.ReadTrace()
		if trace == nil && err == io.EOF {
			// rewind.
			bsize += tell(f)
			f.Seek(0, 0)
			p, _ = parser.NewCpuProfParser(f)
			continue
		}
		_ = count
	}
	bsize += tell(f)
	b.SetBytes(bsize / int64(b.N))
}
