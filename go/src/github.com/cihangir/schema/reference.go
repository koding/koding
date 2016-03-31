package schema

import (
	"fmt"
	"net/url"
	"reflect"
	"regexp"
	"strings"

	"github.com/cihangir/stringext"
)

const (
	fragment  = "#"
	separator = "/"
)

var href = regexp.MustCompile(`({\([^\)]+)\)}`)

// Reference represents a JSON Reference.
type Reference string

// Resolve resolves reference inside a Schema.
func (rf Reference) Resolve(r *Schema) *Schema {
	if !strings.HasPrefix(string(rf), fragment) {
		panic(fmt.Sprintf("non-fragment reference are not supported : %s", rf))
	}
	node := (interface{})(r)
	for _, t := range strings.Split(string(rf), separator)[1:] {
		t = decode(t)
		v := reflect.Indirect(reflect.ValueOf(node))
		switch v.Kind() {
		case reflect.Struct:
			var f reflect.Value
			for i := 0; i < v.NumField(); i++ {
				f = v.Field(i)
				ft := v.Type().Field(i)
				tag := ft.Tag.Get("json")
				if tag == "-" {
					continue
				}
				name := parseTag(tag)
				if name == "" {
					name = ft.Name
				}
				if name == t {
					break
				}
			}
			if !f.IsValid() {
				panic(fmt.Sprintf("can't find '%s' field in %s", t, rf))
			}
			node = f.Interface()
		case reflect.Map:
			kv := v.MapIndex(reflect.ValueOf(t))
			if !kv.IsValid() {
				panic(fmt.Sprintf("can't find '%s' key in %s", t, rf))
			}
			node = kv.Interface()
		default:
			panic(fmt.Sprintf("can't follow pointer : %s", rf))
		}
	}
	return node.(*Schema)
}

func encode(t string) (encoded string) {
	encoded = strings.Replace(t, "/", "~1", -1)
	return strings.Replace(encoded, "~", "~0", -1)
}

func decode(t string) (decoded string) {
	decoded = strings.Replace(t, "~1", "/", -1)
	return strings.Replace(decoded, "~0", "~", -1)
}

func parseTag(tag string) string {
	if i := strings.Index(tag, ","); i != -1 {
		return tag[:i]
	}
	return tag
}

// HRef represents a Link href.
type HRef struct {
	href    string
	Order   []string
	Schemas map[string]*Schema
}

// NewHRef creates a new HRef struct based on a href value.
func NewHRef(href string) *HRef {
	return &HRef{
		href: href,
	}
}

// Resolve resolves a href inside a Schema.
func (h *HRef) Resolve(r *Schema) {
	h.Order = make([]string, 0)
	h.Schemas = make(map[string]*Schema)
	for _, v := range href.FindAllString(string(h.href), -1) {
		u, err := url.QueryUnescape(v[2 : len(v)-2])
		if err != nil {
			panic(err)
		}
		parts := strings.Split(u, "/")
		name := stringext.DepunctWithInitialLower(fmt.Sprintf("%s-%s", parts[len(parts)-3], parts[len(parts)-1]))
		h.Order = append(h.Order, name)
		h.Schemas[name] = Reference(u).Resolve(r)
	}
}

// UnmarshalJSON sets *h to a copy of data.
func (h *HRef) UnmarshalJSON(data []byte) error {
	h.href = string(data[1 : len(data)-1])
	return nil
}

// MarshalJSON returns *h as the JSON encoding of h.
func (h *HRef) MarshalJSON() ([]byte, error) {
	return []byte(h.href), nil
}

// URL returns a usable URL for the href.
func (h *HRef) URL() (*url.URL, error) {
	return url.Parse(string(h.href))
}

func (h *HRef) String() string {
	return href.ReplaceAllStringFunc(string(h.href), func(v string) string {
		return "%v"
	})
}
