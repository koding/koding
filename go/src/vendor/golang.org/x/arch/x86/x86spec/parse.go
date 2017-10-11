// Copyright 2016 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"log"
	"math"
	"os"
	"reflect"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"rsc.io/pdf"
)

// listing holds information about one or more parsed manual pages
// concerning a single instruction listing.
type listing struct {
	pageNum   int
	name      string       // instruction heading
	mtables   [][][]string // mnemonic tables (at most one per page)
	enctables [][][]string // encoding tables (at most one per page)
	compat    string
}

type logReaderAt struct {
	f io.ReaderAt
}

func (l *logReaderAt) ReadAt(x []byte, off int64) (int, error) {
	log.Printf("read %d @ %d", len(x), off)
	return l.f.ReadAt(x, off)
}

const (
	cacheBlockSize = 64 * 1024
	numCacheBlock  = 16
)

type cachedReaderAt struct {
	r     io.ReaderAt
	cache *cacheBlock
}

type cacheBlock struct {
	next   *cacheBlock
	buf    []byte
	offset int64
	err    error
}

func newCachedReaderAt(r io.ReaderAt) *cachedReaderAt {
	c := &cachedReaderAt{
		r: r,
	}
	for i := 0; i < numCacheBlock; i++ {
		c.cache = &cacheBlock{next: c.cache}
	}
	return c
}

func (c *cachedReaderAt) ReadAt(p []byte, offset int64) (n int, err error) {
	// Assume large reads indicate a caller that doesn't need caching.
	if len(p) >= cacheBlockSize {
		return c.r.ReadAt(p, offset)
	}

	for n < len(p) {
		o := offset + int64(n)
		f := o & (cacheBlockSize - 1)
		b := c.readBlock(o - f)
		n += copy(p[n:], b.buf[f:])
		if n < len(p) && b.err != nil {
			return n, b.err
		}
	}
	return n, nil
}

var errShortRead = errors.New("short read")

func (c *cachedReaderAt) readBlock(offset int64) *cacheBlock {
	if offset&(cacheBlockSize-1) != 0 {
		panic("misuse of cachedReaderAt.readBlock")
	}

	// Look in cache.
	var b, prev *cacheBlock
	for b = c.cache; ; prev, b = b, b.next {
		if b.buf != nil && b.offset == offset {
			// Move to front.
			if prev != nil {
				prev.next = b.next
				b.next = c.cache
				c.cache = b
			}
			return b
		}
		if b.next == nil {
			break
		}
	}

	// Otherwise b is LRU block in cache, prev points at b.
	if b.buf == nil {
		b.buf = make([]byte, cacheBlockSize)
	}
	b.offset = offset
	n, err := c.r.ReadAt(b.buf[:cacheBlockSize], offset)
	b.buf = b.buf[:n]
	b.err = err
	if n > 0 {
		// Move to front.
		prev.next = nil
		b.next = c.cache
		c.cache = b
	}
	return b
}

func pdfOpen(name string) (*pdf.Reader, error) {
	f, err := os.Open(name)
	if err != nil {
		return nil, err
	}
	fi, err := f.Stat()
	if err != nil {
		f.Close()
		return nil, err
	}
	return pdf.NewReader(newCachedReaderAt(f), fi.Size())
}

func parse() []*instruction {
	var insts []*instruction

	f, err := pdfOpen(*flagFile)
	if err != nil {
		log.Fatal(err)
	}

	// Find instruction set reference in outline, to build instruction list.
	instList := instHeadings(f.Outline())
	if len(instList) < 200 {
		log.Fatalf("only found %d instructions in table of contents", len(instList))
	}

	// Scan document looking for instructions.
	// Must find exactly the ones in the outline.
	n := f.NumPage()
	var current *listing
	finishInstruction := func() {
		if current == nil {
			return
		}
		if len(current.mtables) == 0 || len(current.mtables[0]) <= 1 {
			fmt.Fprintf(os.Stderr, "p.%d: no mnemonics for instruction %q\n", current.pageNum, current.name)
		}
		processListing(current, &insts)
		current = nil
	}

	for pageNum := 1; pageNum <= n; pageNum++ {
		if onlySomePages && !isDebugPage(pageNum) {
			continue
		}
		p := f.Page(pageNum)
		parsed := parsePage(p, pageNum)
		if parsed.name != "" {
			finishInstruction()
			for j, headline := range instList {
				if parsed.name == headline {
					instList[j] = ""
					current = parsed
					break
				}
			}
			if current == nil {
				fmt.Fprintf(os.Stderr, "p.%d: unexpected instruction %q\n", pageNum, parsed.name)
			}
			continue
		}
		if current != nil {
			merge(current, parsed)
			continue
		}
		if parsed.mtables != nil {
			fmt.Fprintf(os.Stderr, "p.%d: unexpected mnemonic table\n", pageNum)
		}
		if parsed.enctables != nil {
			fmt.Fprintf(os.Stderr, "p.%d: unexpected encoding table\n", pageNum)
		}
		if parsed.compat != "" {
			fmt.Fprintf(os.Stderr, "p.%d: unexpected compatibility statement\n", pageNum)
		}
	}
	finishInstruction()

	if !onlySomePages {
		for _, headline := range instList {
			if headline != "" {
				fmt.Fprintf(os.Stderr, "missing instruction %q\n", headline)
			}
		}
	}

	return insts
}

// isDebugPage reports whether the -debugpage flag mentions page n.
// The argument is a comma-separated list of pages.
// Maybe some day it will support ranges.
func isDebugPage(n int) bool {
	s := *flagDebugPage
	var k int
	for i := 0; ; i++ {
		if i == len(s) || s[i] == ',' {
			if n == k {
				return true
			}
			k = 0
		}
		if i == len(s) {
			break
		}
		if '0' <= s[i] && s[i] <= '9' {
			k = k*10 + int(s[i]) - '0'
		}
	}
	return false
}

// merge merges the content of y into the running collection in x.
func merge(x, y *listing) {
	if y.name != "" {
		fmt.Fprintf(os.Stderr, "p.%d: merging page incorrectly\n", y.pageNum)
		return
	}

	x.mtables = append(x.mtables, y.mtables...)
	x.enctables = append(x.enctables, y.enctables...)
	x.compat += y.compat
}

// instHeadings returns the list of instruction headings from the table of contents.
// When we parse the pages we expect to find every one of these.
func instHeadings(outline pdf.Outline) []string {
	return appendInstHeadings(outline, nil)
}

var instRE = regexp.MustCompile(`\d Instructions \([A-Z]-[A-Z]\)|VMX Instructions|Instruction SET Reference|SHA Extensions Reference`)

// The headings are inconsistent about dash and superscript usage. Normalize.
var fixDash = strings.NewReplacer(
	"Compute 2 –1", "Compute 2^x-1",
	"Compute 2x-1", "Compute 2^x-1",
	"Compute 2x–1", "Compute 2^x-1",
	"/ FUCOMI", "/FUCOMI",
	"Compute y ∗ log x", "Compute y * log₂x",
	"Compute y * log2x", "Compute y * log₂x",
	"Compute y * log2(x +1)", "Compute y * log₂(x+1)",
	"Compute y ∗ log (x +1)", "Compute y * log₂(x+1)",
	" — ", "-",
	"— ", "-",
	" —", "-",
	"—", "-",
	" – ", "-",
	" –", "-",
	"– ", "-",
	"–", "-",
	" - ", "-",
	"- ", "-",
	" -", "-",
)

func appendInstHeadings(outline pdf.Outline, list []string) []string {
	if instRE.MatchString(outline.Title) {
		for _, child := range outline.Child {
			list = append(list, fixDash.Replace(child.Title))
		}
	}
	for _, child := range outline.Child {
		list = appendInstHeadings(child, list)
	}
	return list
}

var dateRE = regexp.MustCompile(`\b(January|February|March|April|May|June|July|August|September|October|November|December) ((19|20)[0-9][0-9])\b`)

// parsePage parses a single PDF page and returns the content it found.
func parsePage(p pdf.Page, pageNum int) *listing {
	if debugging {
		fmt.Fprintf(os.Stderr, "DEBUG: parsing page %d\n", pageNum)
	}

	parsed := new(listing)
	parsed.pageNum = pageNum

	content := p.Content()

	for i, t := range content.Text {
		if match(t, "Symbol", 11, "≠") {
			t.Font = "NeoSansIntel"
			t.FontSize = 9
			content.Text[i] = t
		}
		if t.S == "*" || t.S == "**" || t.S == "***" || t.S == "," && t.Font == "Arial" && t.FontSize < 9 || t.S == "1" && t.Font == "Arial" {
			t.Font = "NeoSansIntel"
			t.FontSize = 9
			if i+1 < len(content.Text) {
				t.Y = content.Text[i+1].Y
			}
			content.Text[i] = t
		}
	}

	text := findWords(content.Text)

	for i, t := range text {
		if match(t, "NeoSansIntel", 8, ".WIG") || match(t, "NeoSansIntel", 8, "AVX2") {
			t.FontSize = 9
			text[i] = t
		}
		if t.Font == "NeoSansIntel-Medium" {
			t.Font = "NeoSansIntelMedium"
			text[i] = t
		}
		if t.Font == "NeoSansIntel-Italic" {
			t.Font = "NeoSansIntel,Italic"
			text[i] = t
		}
	}

	if debugging {
		for _, t := range text {
			fmt.Println(t)
		}
	}

	if pageNum == 1 {
		var buf bytes.Buffer
		for _, t := range text {
			buf.WriteString(t.S + "\n")
		}
		all := buf.String()
		m := regexp.MustCompile(`Order Number: ([\w-\-]+)`).FindStringSubmatch(all)
		num := "???"
		if m != nil {
			num = m[1]
		}
		date := dateRE.FindString(all)
		if date == "" {
			date = "???"
		}

		fmt.Printf("# x86 instruction set description version %s, %s\n",
			specFormatVersion, time.Now().Format("2006-01-02"))
		fmt.Printf("# Based on Intel Instruction Set Reference #%s, %s.\n", num, date)
		fmt.Printf("# https://golang.org/x/arch/x86/x86spec\n")
	}

	// Remove text we should ignore.
	out := text[:0]
	for _, t := range text {
		if shouldIgnore(t) {
			continue
		}
		out = append(out, t)
	}
	text = out

	// Page header must say instruction set reference.
	if len(text) == 0 {
		return parsed
	}
	if (!match(text[0], "NeoSansIntel", 9, "INSTRUCTION") || !match(text[0], "NeoSansIntel", 9, "REFERENCE")) &&
		!match(text[0], "NeoSansIntel", 9, "EXTENSIONS") {
		return parsed
	}
	text = text[1:]

	enctable := findEncodingTable(text)
	if enctable != nil {
		parsed.enctables = append(parsed.enctables, enctable)
	}

	parsed.compat = findCompat(text)

	// Narrow scope for finding mnemonic table.
	// Must be last, since it trims text.
	// Next line is headline. Can wrap to multiple lines.
	if len(text) == 0 || !match(text[0], "NeoSansIntelMedium", 12, "") || !isInstHeadline(text[0].S) {
		if debugging {
			fmt.Fprintf(os.Stderr, "non-inst-headline: %v\n", text[0])
		}
	} else {
		parsed.name = text[0].S
		text = text[1:]
		for len(text) > 0 && match(text[0], "NeoSansIntelMedium", 12, "") {
			parsed.name += " " + text[0].S
			text = text[1:]
		}
		parsed.name = fixDash.Replace(parsed.name)
	}

	// Table follows; heading is NeoSansIntelMedium and rows are NeoSansIntel.
	i := 0
	for i < len(text) && match(text[i], "NeoSansIntelMedium", 9, "") {
		i++
	}
	for i < len(text) && match(text[i], "NeoSansIntel", 9, "") && text[i].S != "NOTES:" {
		i++
	}

	mtable := findMnemonicTable(text[:i])
	if mtable != nil {
		parsed.mtables = append(parsed.mtables, mtable)
	}

	return parsed
}

func match(t pdf.Text, font string, size float64, substr string) bool {
	return t.Font == font && math.Abs(t.FontSize-size) < 0.1 && strings.Contains(t.S, substr)
}

func shouldIgnore(t pdf.Text) bool {
	// Ignore footnote stars, which are in Arial.
	// Also, the page describing MOVS has a tiny 2pt Arial backslash.
	if (t.S == "*" || t.S == "\\") && strings.HasPrefix(t.Font, "Arial") {
		return true
	}

	// Ignore superscript numbers, superscript ST(0), and superscript x.
	if len(t.S) == 1 && '1' <= t.S[0] && t.S[0] <= '9' || t.S == "ST(0)" || t.S == "x" {
		if match(t, "NeoSansIntel", 7.2, "") || match(t, "NeoSansIntel", 5.6, "") || match(t, "NeoSansIntelMedium", 8, "") || match(t, "NeoSansIntelMedium", 9.6, "") {
			return true
		}
	}

	return false
}

func isInstHeadline(s string) bool {
	return strings.Contains(s, "—") ||
		strings.Contains(s, " - ") ||
		strings.Contains(s, "PTEST- Logical Compare")
}

func findWords(chars []pdf.Text) (words []pdf.Text) {
	// Sort by Y coordinate and normalize.
	const nudge = 1
	sort.Sort(pdf.TextVertical(chars))
	old := -100000.0
	for i, c := range chars {
		if c.Y != old && math.Abs(old-c.Y) < nudge {
			chars[i].Y = old
		} else {
			old = c.Y
		}
	}

	// Sort by Y coordinate, breaking ties with X.
	// This will bring letters in a single word together.
	sort.Sort(pdf.TextVertical(chars))

	// Loop over chars.
	for i := 0; i < len(chars); {
		// Find all chars on line.
		j := i + 1
		for j < len(chars) && chars[j].Y == chars[i].Y {
			j++
		}
		var end float64
		// Split line into words (really, phrases).
		for k := i; k < j; {
			ck := &chars[k]
			s := ck.S
			end = ck.X + ck.W
			charSpace := ck.FontSize / 6
			wordSpace := ck.FontSize * 2 / 3
			l := k + 1
			for l < j {
				// Grow word.
				cl := &chars[l]
				if sameFont(cl.Font, ck.Font) && cl.FontSize == ck.FontSize && cl.X <= end+charSpace {
					s += cl.S
					end = cl.X + cl.W
					l++
					continue
				}
				// Add space to phrase before next word.
				if sameFont(cl.Font, ck.Font) && cl.FontSize == ck.FontSize && cl.X <= end+wordSpace {
					s += " " + cl.S
					end = cl.X + cl.W
					l++
					continue
				}
				break
			}
			f := ck.Font
			f = strings.TrimSuffix(f, ",Italic")
			f = strings.TrimSuffix(f, "-Italic")
			words = append(words, pdf.Text{f, ck.FontSize, ck.X, ck.Y, end, s})
			k = l
		}
		i = j
	}

	return words
}

func sameFont(f1, f2 string) bool {
	f1 = strings.TrimSuffix(f1, ",Italic")
	f1 = strings.TrimSuffix(f1, "-Italic")
	f2 = strings.TrimSuffix(f1, ",Italic")
	f2 = strings.TrimSuffix(f1, "-Italic")
	return strings.TrimSuffix(f1, ",Italic") == strings.TrimSuffix(f2, ",Italic") || f1 == "Symbol" || f2 == "Symbol" || f1 == "TimesNewRoman" || f2 == "TimesNewRoman"
}

func findMnemonicTable(text []pdf.Text) [][]string {
	sort.Sort(pdf.TextHorizontal(text))

	const nudge = 1

	old := -100000.0
	var col []float64
	for i, t := range text {
		if t.Font != "NeoSansIntelMedium" { // only headings count
			continue
		}
		if t.X != old && math.Abs(old-t.X) < nudge {
			text[i].X = old
		} else if t.X != old {
			old = t.X
			col = append(col, old)
		}
	}
	sort.Sort(pdf.TextVertical(text))

	if len(col) == 0 {
		return nil
	}

	y := -100000.0
	var table [][]string
	var line []string
	bold := -1
	for _, t := range text {
		if t.Y != y {
			table = append(table, make([]string, len(col)))
			line = table[len(table)-1]
			y = t.Y
			if t.Font == "NeoSansIntelMedium" {
				bold = len(table) - 1
			}
		}
		i := 0
		for i+1 < len(col) && col[i+1] <= t.X+nudge {
			i++
		}
		if line[i] != "" {
			line[i] += " "
		}
		line[i] += t.S
	}

	var mtable [][]string
	for i, t := range table {
		if 0 < i && i <= bold || bold < i && halfMissing(t) {
			// merge with earlier line
			last := mtable[len(mtable)-1]
			for j, s := range t {
				if s != "" {
					last[j] += "\n" + s
				}
			}
		} else {
			mtable = append(mtable, t)
		}
	}

	if bold >= 0 {
		heading := mtable[0]
		for i, x := range heading {
			heading[i] = fixHeading.Replace(x)
		}
	}

	return mtable
}

var fixHeading = strings.NewReplacer(
	"64/32-\nbit\nMode", "64/32-Bit Mode",
	"64/32-\nbit Mode", "64/32-Bit Mode",
	"64/32-bit\nMode", "64/32-Bit Mode",
	"64/3\n2-bit\nMode", "64/32-Bit Mode",
	"64/32 bit\nMode\nSupport", "64/32-Bit Mode",
	"64/32bit\nMode\nSupport", "64/32-Bit Mode",
	"64/32\n-bit\nMode", "64/32-Bit Mode",
	"64/32\nbit Mode\nSupport", "64/32-Bit Mode",
	"64-Bit\nMode", "64-Bit Mode",
	"64-bit\nMode", "64-Bit Mode",

	"Op/ En", "Op/En",
	"Op/\nEn", "Op/En",
	"Op/\nEN", "Op/En",
	"Op /\nEn", "Op/En",
	"Opcode***", "Opcode",
	"Opcode**", "Opcode",
	"Opcode*", "Opcode",
	"/\nInstruction", "/Instruction",

	"CPUID Fea-\nture Flag", "CPUID Feature Flag",
	"CPUID\nFeature\nFlag", "CPUID Feature Flag",
	"CPUID\nFeature Flag", "CPUID Feature Flag",
	"CPUIDFeature\nFlag", "CPUID Feature Flag",

	"Compat/\nLeg Mode*", "Compat/Leg Mode",
	"Compat/\nLeg Mode", "Compat/Leg Mode",
	"Compat/ *\nLeg Mode", "Compat/Leg Mode",
)

func halfMissing(x []string) bool {
	n := 0
	for _, s := range x {
		if s == "" {
			n++
		}
	}
	return n >= len(x)/2
}

func findEncodingTable(text []pdf.Text) [][]string {
	// Look for operand encoding table.
	sort.Sort(pdf.TextVertical(text))
	var col []float64
	sawTitle := false

	center := func(t pdf.Text) float64 {
		return t.X + t.W/2
	}

	start := 0
	end := len(text)
	for i, t := range text {
		if match(t, "NeoSansIntelMedium", 10, "Instruction Operand Encoding") {
			sawTitle = true
			start = i + 1
			continue
		}
		if !sawTitle {
			continue
		}
		if match(t, "NeoSansIntel", 9, "Op/En") || match(t, "NeoSansIntel", 9, "Operand") {
			if debugging {
				fmt.Printf("column %d at %.2f: %v\n", len(col), center(t), t)
			}
			col = append(col, center(t))
		}
		if match(t, "NeoSansIntelMedium", 10, "Description") {
			end = i
			break
		}
	}
	text = text[start:end]

	if len(col) == 0 {
		return nil
	}

	const nudge = 20

	y := -100000.0
	var table [][]string
	var line []string
	for _, t := range text {
		if t.Y != y {
			table = append(table, make([]string, len(col)))
			line = table[len(table)-1]
			y = t.Y
		}
		i := 0
		x := center(t)
		for i+1 < len(col) && col[i+1] <= x+nudge {
			i++
		}
		if debugging {
			fmt.Printf("text at %.2f: %v => %d\n", x, t, i)
		}
		if line[i] != "" {
			line[i] += " "
		}
		line[i] += t.S
	}

	out := table[:0]
	for _, line := range table {
		if strings.HasPrefix(line[len(line)-1], "Vol. 2") { // page footer
			continue
		}
		if line[0] == "" && len(out) > 0 {
			last := out[len(out)-1]
			for i, col := range line {
				if col != "" {
					last[i] += " " + col
				}
			}
			continue
		}
		out = append(out, line)
	}
	table = out

	return table
}

func findCompat(text []pdf.Text) string {
	sort.Sort(pdf.TextVertical(text))

	inCompat := false
	out := ""
	for _, t := range text {
		if match(t, "NeoSansIntelMedium", 10, "") {
			inCompat = strings.Contains(t.S, "Architecture Compatibility")
			if inCompat {
				out += t.S + "\n"
			}
		}
		if inCompat && match(t, "Verdana", 9, "") || strings.Contains(t.S, "were introduced") {
			out += t.S + "\n"
		}
	}
	return out
}

func processListing(p *listing, insts *[]*instruction) {
	if debugging {
		for _, table := range p.mtables {
			fmt.Printf("table:\n")
			for _, row := range table {
				fmt.Printf("%q\n", row)
			}
		}
		fmt.Printf("enctable:\n")
		for _, table := range p.enctables {
			for _, row := range table {
				fmt.Printf("%q\n", row)
			}
		}
		fmt.Printf("compat:\n%s", p.compat)
	}

	if *flagCompat && p.compat != "" {
		fmt.Printf("# p.%d: %s\n#\t%s\n", p.pageNum, p.name, strings.Replace(p.compat, "\n", "\n#\t", -1))
	}

	encs := make(map[string][]string)
	for _, table := range p.enctables {
		for _, row := range table[1:] {
			for len(row) > 1 && (row[len(row)-1] == "NA" || row[len(row)-1] == "" || row[len(row)-1] == " source") {
				row = row[:len(row)-1]
			}
			encs[row[0]] = row[1:]
		}
	}

	var wrong string
	for _, table := range p.mtables {
		heading := table[0]
		for _, row := range table[1:] {
			if row[0] == heading[0] && reflect.DeepEqual(row, heading) {
				continue
			}
			if len(row) >= 5 && row[1] == "CMOVG r64, r/m64" && row[3] == "V/N.E." && row[4] == "NA" {
				row[3] = "V"
				row[4] = "N.E."
			}
			inst := new(instruction)
			inst.page = p.pageNum
			inst.compat = strings.Join(strings.Fields(p.compat), " ")
			for i, hdr := range heading {
				x := row[i]
				x = strings.Replace(x, "\n", " ", -1)
				switch strings.TrimSpace(hdr) {
				default:
					wrong = "unexpected header: " + strconv.Quote(hdr)
					goto BadTable
				case "Opcode/Instruction":
					x = row[i]
					if strings.HasPrefix(x, "\nVEX") {
						x = x[1:]
						row[i] = x
					}
					if strings.Contains(x, "\n/r ") {
						x = strings.Replace(x, "\n/r ", " /r ", -1)
						row[i] = x
					}
					if strings.Contains(x, ",\nimm") {
						x = strings.Replace(x, ",\nimm", ", imm", -1)
						row[i] = x
					}
					if strings.Count(x, "\n") < 1 {
						wrong = "bad Opcode/Instruction pairing: " + strconv.Quote(x)
						goto BadTable
					}
					i := strings.Index(x, "\n")
					inst.opcode = x[:i]
					inst.syntax = strings.Replace(x[i+1:], "\n", " ", -1)

				case "Opcode":
					inst.opcode = x

				case "Instruction":
					inst.syntax = x

				case "Op/En":
					inst.args = encs[x]
					if inst.args == nil && len(encs) == 1 && encs["A"] != nil {
						inst.args = encs["A"]
					}
					// In the December 2015 manual, PREFETCHW says
					// encoding A but the table gives encoding M.
					if inst.args == nil && inst.syntax == "PREFETCHW m8" && x == "A" && len(encs) == 1 && encs["M"] != nil {
						inst.args = encs["M"]
					}

				case "64-Bit Mode":
					x, ok := parseMode(x)
					if !ok {
						wrong = "unexpected value for 64-Bit Mode column: " + x
						goto BadTable
					}
					inst.valid64 = x

				case "Compat/Leg Mode":
					x, ok := parseMode(x)
					if !ok {
						wrong = "unexpected value for Compat/Leg Mode column: " + x
						goto BadTable
					}
					inst.valid32 = x

				case "64/32-Bit Mode":
					i := strings.Index(x, "/")
					if i < 0 {
						wrong = "unexpected value for 64/32-Bit Mode column: " + x
						goto BadTable
					}
					x1, ok1 := parseMode(x[:i])
					x2, ok2 := parseMode(x[i+1:])
					if !ok1 || !ok2 {
						wrong = "unexpected value for 64/32-Bit Mode column: " + x
						goto BadTable
					}
					inst.valid64 = x1
					inst.valid32 = x2

				case "CPUID Feature Flag":
					inst.cpuid = x

				case "Description":
					if inst.desc != "" {
						inst.desc += " "
					}
					inst.desc += x
				}
			}

			// Fixup various typos or bugs in opcode descriptions.
			if inst.opcode == "VEX.128.66.0F.W0 6E /" {
				inst.opcode += "r"
			}
			fix := func(old, new string) {
				inst.opcode = strings.Replace(inst.opcode, old, new, -1)
			}
			fix(" imm8", " ib")
			fix("REX.w", "REX.W")
			fix("REX.W+", "REX.W +")
			fix(" 0f ", " 0F ")
			fix(". 0F38", ".0F38")
			fix("0F .WIG", "0F.WIG")
			fix("0F38 .WIG", "0F38.WIG")
			fix("NDS .LZ", "NDS.LZ")
			fix("58+ r", "58+r")
			fix("B0+ ", "B0+")
			fix("B8+ ", "B8+")
			fix("40+ ", "40+")
			fix("*", "")
			fix(",", " ")
			fix("/", " /")
			fix("REX.W +", "REX.W")
			fix("REX +", "REX")
			fix("REX 0F BE", "REX.W 0F BE")
			fix("REX 0F B2", "REX.W 0F B2")
			fix("REX 0F B4", "REX.W 0F B4")
			fix("REX 0F B5", "REX.W 0F B5")
			fix("0F38.0", "0F38.W0")
			fix(".660F.", ".66.0F.")
			fix("VEX128", "VEX.128")
			fix("0F3A.W0.1D", "0F3A.W0 1D")

			inst.opcode = strings.Join(strings.Fields(inst.opcode), " ")

			fix = func(old, new string) {
				inst.syntax = strings.Replace(inst.syntax, old, new, -1)
			}
			fix("xmm1 xmm2", "xmm1, xmm2")
			fix("r16/m16", "r/m16")
			fix("r32/m161", "r32/m16") // really r32/m16¹ (footnote)
			fix("r32/m32", "r/m32")
			fix("r64/m64", "r/m64")
			fix("\u2013", "-")
			fix("mm3 /m", "mm3/m")
			fix("mm3/.m", "mm3/m")
			inst.syntax = joinSyntax(splitSyntax(inst.syntax))

			fix = func(old, new string) {
				inst.cpuid = strings.Replace(inst.cpuid, old, new, -1)
			}
			fix("PCLMUL- QDQ", "PCLMULQDQ")
			fix("PCL- MULQDQ", "PCLMULQDQ")
			fix("Both PCLMULQDQ and AVX flags", "PCLMULQDQ+AVX")

			if !instBlacklist[inst.syntax] {
				*insts = append(*insts, inst)
			}
		}
	}
	return

BadTable:
	fmt.Fprintf(os.Stderr, "p.%d: reading %v: %v\n", p.pageNum, p.name, wrong)
	for _, table := range p.mtables {
		for _, t := range table {
			fmt.Fprintf(os.Stderr, "\t%q\n", t)
		}
	}
	fmt.Fprintf(os.Stderr, "\n")
}

func parseMode(s string) (string, bool) {
	switch strings.TrimSpace(s) {
	case "Invalid", "Invalid*", "Inv.", "I", "i":
		return "I", true
	case "Valid", "Valid*", "V":
		return "V", true
	case "N.E.", "NE", "N. E.":
		return "N.E.", true
	case "N.P.", "N. P.":
		return "N.P.", true
	case "N.S.", "N. S.":
		return "N.S.", true
	case "N.I.", "N. I.":
		return "N.I.", true
	}
	return s, false
}

func splitSyntax(syntax string) (op string, args []string) {
	i := strings.Index(syntax, " ")
	if i < 0 {
		return syntax, nil
	}
	op, syntax = syntax[:i], syntax[i+1:]
	args = strings.Split(syntax, ",")
	for i, arg := range args {
		arg = strings.TrimSpace(arg)
		arg = strings.TrimRight(arg, "*")
		args[i] = arg
	}
	return
}

func joinSyntax(op string, args []string) string {
	if len(args) == 0 {
		return op
	}
	return op + " " + strings.Join(args, ", ")
}
