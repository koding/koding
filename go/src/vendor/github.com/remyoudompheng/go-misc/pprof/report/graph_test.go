package report

import (
	"bytes"
	"io"
	"os"
	"testing"

	"github.com/remyoudompheng/go-misc/pprof/parser"
)

func TestCpuProfileGraph(t *testing.T) {
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
	total := int64(0)
	for {
		trace, count, err := p.ReadTrace()
		if trace == nil && err == io.EOF {
			break
		}
		reporter.Add(trace, int64(count))
		total += int64(count)
	}

	g := reporter.GraphByFunc(ColCPU)
	t.Logf("%#v", g)
	report := GraphReport{
		Prog:  "pprof.test",
		Total: total,
		Unit:  "samples",
		Graph: g,
	}

	buf := new(bytes.Buffer)
	err = graphvizTpl.Execute(buf, report)
	if err != nil {
		t.Fatal(err)
	}
	t.Log(buf.String())
}
