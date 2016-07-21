package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"go/format"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
	"sort"
	"strings"
	"text/template"
	"time"
	"unicode"
)

var dir = flag.String("dir", "", "directory with json files")
var files = flag.String("files", "", "comma-seperated json filepaths")
var tags = flag.String("tags", "", "comma-seperated tags for structs. Note - json is forced")
var fieldTypes = flag.String("types", "", "comma-seperated forced types eg. 'created_at:Time'")
var output = flag.String("o", "stdout", "")
var pkgOpt = flag.String("pkg", "", "package name")

type tagType struct {
	Package string
	Name    string
	Extra   []string
}

func (t *tagType) String() string {
	if t.Extra != nil {
		return fmt.Sprintf("%s:\"%s,%s\"", t.Package, t.Name, strings.Join(t.Extra, ","))
	}
	return fmt.Sprintf("%s:\"%s\"", t.Package, t.Name)
}

type rawEvent struct {
	Name        string
	PayloadJSON string
}

type member struct {
	Name string
	Typ  string
	Tags []tagType
}

type object struct {
	Name    string
	Members []member
}

type rawEventSlice []rawEvent

func (p rawEventSlice) Len() int           { return len(p) }
func (p rawEventSlice) Less(i, j int) bool { return p[i].Name < p[j].Name }
func (p rawEventSlice) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }
func (p rawEventSlice) Sort()              { sort.Sort(p) }

func (p rawEventSlice) Contains(event string) bool {
	i := sort.Search(len(p), func(i int) bool { return p[i].Name >= event })
	return i != len(p) && p[i].Name == event
}

func unique(events []rawEvent) []string {
	var unique = make(map[string]struct{})
	for i := range events {
		unique[events[i].Name] = struct{}{}
	}
	s := make([]string, 0, len(unique))
	for k := range unique {
		s = append(s, k)
	}
	sort.Strings(s)
	return s
}

type memberSet []member

func (ms memberSet) Search(name string) int {
	return sort.Search(len(ms), func(i int) bool { return ms[i].Name >= name })
}

func (ms *memberSet) Add(m member) {
	// Member's type can be empty, when it duplicates type of its parent;
	// ignore it as recursive types are not supported.
	if m.Typ == "" {
		return
	}
	switch i := ms.Search(m.Name); {
	case i == len(*ms):
		*ms = append(*ms, m)
	case (*ms)[i].Name == m.Name:
		if typ := (*ms)[i].Typ; typ != m.Typ {
			// The "created_at" and "pushed_at" keys storing timestamps instead
			// of RFC3339 time for PushEvent looks like a bug. Force use of
			// the Time type.
			if m.Name == "CreatedAt" || m.Name == "PushedAt" {
				(*ms)[i].Typ = "Time"
				break
			}
			(*ms)[i].Typ = "interface{}"
			fmt.Fprintf(os.Stderr, "different types for %s member: %s and %s, using interface{}\n", m.Name, typ, m.Typ)
		}
	default:
		*ms = append(*ms, member{})
		copy((*ms)[i+1:], (*ms)[i:])
		(*ms)[i] = m
	}
}

type objectSet []object

func (os objectSet) Search(name string) int {
	return sort.Search(len(os), func(i int) bool { return os[i].Name >= name })
}

func (os *objectSet) Add(o object) {
	switch i := os.Search(o.Name); {
	case i == len(*os):
		*os = append(*os, o)
	case (*os)[i].Name == o.Name:
		for _, m := range o.Members {
			// Ignore members which are named after structs to not create
			// invalid recursive types.
			if o.Name == m.Name && m.Name == m.Typ {
				continue
			}
			(*memberSet)(&(*os)[i].Members).Add(m)
		}
	default:
		*os = append(*os, object{})
		copy((*os)[i+1:], (*os)[i:])
		(*os)[i] = o
	}
}

type typeTree struct {
	m     map[string]interface{}
	tags  []string
	types map[string]string
}

func newTypeTree(events []rawEvent, types map[string]string, tags ...string) typeTree {
	t := typeTree{
		make(map[string]interface{}, len(events)),
		tags,
		types,
	}
	for _, e := range events {
		t.push(e)
	}
	return t
}

func (t typeTree) push(e rawEvent) {
	type node struct {
		typ, v map[string]interface{}
	}
	var v map[string]interface{}
	if err := json.Unmarshal([]byte(e.PayloadJSON), &v); err != nil {
		die(err)
	}
	typ, ok := t.m[e.Name].(map[string]interface{})
	if !ok {
		t.m[e.Name] = v
		return
	}
	nd, stack := node{}, []node{{typ: typ, v: v}}
	for n := len(stack); n != 0; n = len(stack) {
		nd, stack = stack[n-1], stack[:n-1]
		for k, v := range nd.v {
			typ, ok := nd.typ[k]
			if !ok {
				nd.typ[k] = v
				continue
			}
			switch rtyp, rv := reflect.TypeOf(typ), reflect.TypeOf(v); {
			case rtyp == nil && rv != nil && rv.Kind() == reflect.Map:
				typ = make(map[string]interface{})
				nd.typ[k] = typ
			case rtyp != nil && rv != nil && rtyp != rv:
				die(fmt.Sprintf("merge: incompatible types for %s: %T vs %v", k, v, typ))
			default:
				if v, ok := v.(map[string]interface{}); ok {
					stack = append(stack, node{typ: typ.(map[string]interface{}), v: v})
				}
			}
		}
	}
}

func (t typeTree) objects() (obj []object) {
	var stack = make([]node, 0, len(t.m))
	for k, v := range t.m {
		v, ok := v.(map[string]interface{})
		if !ok {
			die(fmt.Sprintf("%s is not a JSON object", k))
		}
		stack = append(stack, node{name: k, nodes: v})
	}
	var nd node
	for n := len(stack); n != 0; n = len(stack) {
		nd, stack = stack[n-1], stack[:n-1]
		o := object{Name: nd.name, Members: make([]member, 0, len(nd.nodes))}
		for k, v := range nd.nodes {
			// Ignore "_links" member as it's redundant and it pollutes a number
			// of structs with a "href" member.
			if k == "_links" {
				continue
			}
			var tags = []tagType{{Package: "json", Name: k}}
			for _, tag := range t.tags {
				if tag == "json" {
					continue
				}
				tags = append(tags, tagType{Package: tag, Name: k})
			}
			m := member{Name: camelCase(k), Tags: tags}
			t.setType(&m, v, nd.name, &stack)
			(*memberSet)(&o.Members).Add(m)
		}
		(*objectSet)(&obj).Add(o)
	}
	return obj
}

const header = `// Created by go generate; DO NOT EDIT

package {{pkg}}

`

const types = `{{range $_, $o := .}}// {{$o.Name}} was autogenerated by go generate.
type {{$o.Name}} struct {
{{range $_, $m := $o.Members}}  {{$m.Name}} {{$m.Typ}} ` + "`{{join $m.Tags}}`" + `
{{end}}
}
{{end}}
`

var tmplHeader = template.Must(template.New("payloads").Funcs(map[string]interface{}{"snakeCase": snakeCase, "pkg": pkg}).Parse(header))
var tmplTypes = template.Must(template.New("payloads").Funcs(map[string]interface{}{"join": joinTags}).Parse(types))

var idiomaticReplacer = strings.NewReplacer("Url", "URL", "Id", "ID", "Html", "HTML", "Sha", "SHA", "Ssh", "SSH")

func joinTags(t []tagType) string {
	str := ""
	for _, tag := range t {
		str += tag.String() + " "
	}
	return strings.TrimRight(str, " ")
}

func pkg() string {
	if *pkgOpt == "" {
		flag.PrintDefaults()
		os.Exit(1)
	}
	return *pkgOpt
}

func nonil(err ...error) error {
	for _, err := range err {
		if err != nil {
			return err
		}
	}
	return nil
}

func die(v interface{}) {
	fmt.Fprintln(os.Stderr, v)
	os.Exit(1)
}

func snakeCase(s string) (t string) {
	if i := strings.Index(s, "Event"); i != -1 {
		s = s[:i]
	}
	for _, c := range s {
		if unicode.IsUpper(c) {
			t = t + "_" + string(unicode.ToLower(c))
		} else {
			t = t + string(c)
		}
	}
	return strings.Trim(t, "_")
}

func camelCase(s string) (t string) {
	up := true
	for _, r := range s {
		switch r {
		case ' ', '-', '_':
			up = true
		default:
			if up {
				t = t + string(unicode.ToUpper(r))
				up = false
			} else {
				t = t + string(r)
			}
		}
	}
	return idiomaticReplacer.Replace(t)
}

type node struct {
	name  string
	nodes map[string]interface{}
}

func (t typeTree) hardcodedType(m *member) (string, bool) {
	if m.Tags == nil {
		panic("Tags field must not be empty!")
	}
	typ, ok := t.types[m.Tags[0].Name]
	return typ, ok
}

func (t typeTree) setType(m *member, v interface{}, parent string, stack *[]node) {
	var setType func(*member, interface{}, string, *[]node)
	setType = func(m *member, v interface{}, parent string, stack *[]node) {
		if typ, ok := t.hardcodedType(m); ok {
			m.Typ = typ
			return
		}
		switch v := v.(type) {
		case map[string]interface{}:
			if parent == m.Name {
				// Ignore members which are named after structs to not create
				// invalid recursive types.
				break
			}
			m.Typ = m.Name
			// Files is a member of a gist object, it's handled separately since
			// it's a map.
			//
			// https://developer.github.com/v3/gists/
			if m.Typ != "Files" {
				*stack = append(*stack, node{name: m.Name, nodes: v})
			}
		case bool:
			m.Typ = "bool"
		case float64:
			m.Typ = "float64"
		case []interface{}:
			if len(v) == 0 {
				m.Typ = "[]string"
				break
			}
			var prev = *m
			var cur = *m
			for _, v := range v {
				setType(&cur, v, "", stack)
				if prev.Typ != "" && cur.Typ != prev.Typ {
					die(fmt.Sprintf("heterogeneous arrays not supported: %s, %s", prev.Typ, cur.Typ))
				}
				prev = cur
			}
			m.Typ = "[]" + cur.Typ
		case string:
			switch err := (&time.Time{}).UnmarshalText([]byte(v)); err {
			case nil:
				m.Typ = "Time"
			default:
				m.Typ = "string"
			}
		default:
			die(fmt.Sprintf("unable to guess type for %s: %T", m.Name, v))
		}
	}
	setType(m, v, parent, stack)
}

func readData(dir string, fis ...os.FileInfo) (events []rawEvent) {
	for _, fi := range fis {
		event := strings.ToLower(fi.Name())
		if !strings.HasSuffix(event, ".json") {
			log.Println("webhook: ignoring", fi.Name())
			continue
		}
		if i := strings.IndexRune(event, '-'); i != -1 {
			event = event[:i]
		} else {
			event = event[:len(event)-len(".json")]
		}
		event = camelCase(event)
		log.Printf("webhook: reading %s (%s) . . .", fi.Name(), event)
		if (*rawEventSlice)(&events).Contains(event) {
			fmt.Fprintf(os.Stderr, "merging duplicate JSON file for %q event . . .\n", event)
		}
		body, err := ioutil.ReadFile(filepath.Join(dir, fi.Name()))
		if err != nil {
			die(err)
		}
		events = append(events, rawEvent{Name: event, PayloadJSON: string(body)})
	}
	return events
}

func statFiles(files string) ([]os.FileInfo, error) {
	var fis []os.FileInfo
	fs := strings.Split(files, ",")
	for _, f := range fs {
		fi, err := os.Stat(f)
		if err != nil {
			return nil, err
		}
		fis = append(fis, fi)
	}
	return fis, nil
}

var reTypes = regexp.MustCompile("(\\S+):(\\S+)")

func parseTypes(types string) map[string]string {
	m := make(map[string]string)
	ts := strings.Split(types, ",")
	for _, t := range ts {
		match := reTypes.FindStringSubmatch(t)
		if match == nil {
			return nil
		}
		m[match[1]] = match[2]
	}
	return m
}

func main() {
	flag.Parse()
	var events []rawEvent
	var fis []os.FileInfo
	if *dir == "" {
		flag.PrintDefaults()
		os.Exit(1)
	}
	fis, err := ioutil.ReadDir(*dir)
	if err != nil {
		die(err)
	}
	events = readData(*dir, fis...)
	rawEventSlice(events).Sort()
	for i := range events {
		if events[i].PayloadJSON == "" {
			die(fmt.Sprintf("empty payload for %q event (i=%d)", events[i].Name, i))
		}
	}
	buf := bytes.NewBuffer([]byte(""))
	if err := tmplHeader.Execute(buf, unique(events)); err != nil {
		die(err)
	}
	typeMap := parseTypes(*fieldTypes)
	if err := tmplTypes.Execute(buf,
		newTypeTree(events, typeMap, strings.Split(*tags, ",")...).objects()); err != nil {
		die(err)
	}
	b, err := format.Source(buf.Bytes())
	if err != nil {
		die(err)
	}
	if *output == "stdout" {
		fmt.Fprintln(os.Stdout, string(b))
		os.Exit(0)
	}
	if err = ioutil.WriteFile(*output, b, 0655); err != nil {
		die(err)
	}
}
