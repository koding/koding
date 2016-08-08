package report

import (
	"bufio"
	"bytes"
	"debug/elf"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strconv"
	"strings"
)

// A Reporter is used to produce reports from profile data.
type Reporter struct {
	Resolver  Resolver
	stats     map[uint64]*Stats // stats per PC.
	freeStats []Stats           // allocation pool.
}

// A Resolver associates a symbol to a numeric address.
type Resolver interface {
	Resolve(uint64) string
}

type Stats struct {
	Self    [4]int64
	Cumul   [4]int64
	Callees map[uint64][4]int64
}

func (r *Reporter) getStats(key uint64) *Stats {
	if p := r.stats[key]; p != nil {
		return p
	}
	if len(r.freeStats) == 0 {
		r.freeStats = make([]Stats, 64)
	}
	s := &r.freeStats[0]
	r.freeStats = r.freeStats[1:]
	r.stats[key] = s
	return s
}

func (r *Reporter) Total(col int) (t int64) {
	for _, s := range r.stats {
		t += s.Self[col]
	}
	return
}

func (r *Reporter) Symbols() (as []uint64) {
	seen := make(map[uint64]bool, len(r.stats))
	for a, v := range r.stats {
		if !seen[a] {
			seen[a] = true
			as = append(as, a)
		}
		for b := range v.Callees {
			if !seen[b] {
				seen[b] = true
				as = append(as, b)
			}
		}
	}
	return
}

func (r *Reporter) SetExecutable(filename string) error {
	f, err := elf.Open(filename)
	if err != nil {
		return err
	}
	defer f.Close()
	symbols, err := f.Symbols()
	if err != nil {
		return err
	}
	sort.Sort(elfSymbolTable(symbols))
	r.Resolver = elfSymbolTable(symbols)
	return nil
}

// Add registers data for a given stack trace. There may be at most
// 4 count arguments, as needed in heap profiles.
func (r *Reporter) Add(trace []uint64, count ...int64) {
	if r.stats == nil {
		r.stats = make(map[uint64]*Stats)
	}
	if len(count) > 4 {
		err := fmt.Errorf("too many counts (%d) to register in reporter", len(count))
		panic(err)
	}
	// Only the last point.
	s := r.getStats(trace[0])
	for i, n := range count {
		s.Self[i] += n
	}
	// Record cumulated stats.
	seen := make(map[uint64]bool, len(trace))
	for i, a := range trace {
		s := r.getStats(a)
		if !seen[a] {
			seen[a] = true
			for j, n := range count {
				s.Cumul[j] += n
			}
		}
		if i > 0 {
			callee := trace[i-1]
			if s.Callees == nil {
				s.Callees = make(map[uint64][4]int64)
			}
			edges := s.Callees[callee]
			for j, n := range count {
				edges[j] += n
			}
			s.Callees[callee] = edges
		}
	}
}

const (
	ColCPU        = 0
	ColLiveObj    = 0
	ColLiveBytes  = 1
	ColAllocObj   = 2
	ColAllocBytes = 3
)

func (r *Reporter) ReportByFunc(column int) []ReportLine {
	lines := make(map[string][2][4]float64, len(r.stats))
	for a, v := range r.stats {
		name := r.Resolver.Resolve(a)
		s := lines[name]
		for i := 0; i < 4; i++ {
			s[0][i] += float64(v.Self[i])
			s[1][i] += float64(v.Cumul[i])
		}
		lines[name] = s
	}
	entries := make([]ReportLine, 0, len(lines))
	for name, values := range lines {
		entries = append(entries, ReportLine{Name: name,
			Self: values[0], Cumul: values[1]})
	}
	sort.Sort(bySelf{entries, column})
	return entries
}

func (r *Reporter) ReportByPC() []ReportLine {
	return nil
}

type ReportLine struct {
	Name        string
	Self, Cumul [4]float64
}

type bySelf struct {
	slice []ReportLine
	col   int
}

func (s bySelf) Len() int      { return len(s.slice) }
func (s bySelf) Swap(i, j int) { s.slice[i], s.slice[j] = s.slice[j], s.slice[i] }

func (s bySelf) Less(i, j int) bool {
	left, right := s.slice[i].Self[s.col], s.slice[j].Self[s.col]
	if left > right {
		return true
	}
	if left == right {
		return s.slice[i].Name < s.slice[j].Name
	}
	return false
}

type byCumul bySelf

func (s byCumul) Len() int      { return len(s.slice) }
func (s byCumul) Swap(i, j int) { s.slice[i], s.slice[j] = s.slice[j], s.slice[i] }

func (s byCumul) Less(i, j int) bool {
	left, right := s.slice[i].Cumul[s.col], s.slice[j].Cumul[s.col]
	if left > right {
		return true
	}
	if left == right {
		return s.slice[i].Name < s.slice[j].Name
	}
	return false
}

// Symbol resolvers.

type elfSymbolTable []elf.Symbol

func (s elfSymbolTable) Len() int           { return len(s) }
func (s elfSymbolTable) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }
func (s elfSymbolTable) Less(i, j int) bool { return s[i].Value < s[j].Value }

func (s elfSymbolTable) Resolve(addr uint64) string {
	min, max := 0, len(s)
	for max-min > 1 {
		med := (min + max) / 2
		a := s[med].Value
		if a < addr {
			min = med
		} else {
			max = med
		}
	}
	if s[min].Value > addr {
		return "N/A"
	}
	return s[min].Name
}

type RemoteResolver struct {
	Url     string
	Symbols map[uint64]string
}

func (nr *RemoteResolver) Prepare(addrs []uint64) error {
	buf := new(bytes.Buffer)
	for i, addr := range addrs {
		if i > 0 {
			buf.WriteByte('+')
		}
		fmt.Fprintf(buf, "%#x", addr)
	}
	resp, err := http.Post(nr.Url, "text/plain", buf)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if nr.Symbols == nil {
		nr.Symbols = make(map[uint64]string)
	}
	r := bufio.NewReader(resp.Body)
	for {
		line, err := r.ReadString('\n')
		if strings.TrimSpace(line) == "" && err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		if strings.HasPrefix(line, "num_symbols") {
			continue
		}
		// Lines have the form "0xabcdef symbol_name"
		words := strings.Fields(line)
		if len(words) != 2 {
			return fmt.Errorf("bad symbol file format")
		}
		addr, sym := words[0], words[1]
		a, err := strconv.ParseUint(addr, 0, 64)
		if err != nil {
			return err
		}
		nr.Symbols[a] = sym
	}
	return nil
}

func (nr *RemoteResolver) Resolve(addr uint64) string {
	return nr.Symbols[addr]
}
