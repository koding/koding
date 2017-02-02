package sl

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// Tags represents the resource tags.
//
// If Softlayer does not support tagging the resource, it's
// emulated by keeping stringified JSON of the tags
// in the Description, Comment or Note field of the resource.
type Tags map[string]string

// NewTags creates Tags for the given kev=value list.
func NewTags(kv []string) Tags {
	if len(kv) == 0 {
		return nil
	}
	t := make(Tags)
	for _, kv := range kv {
		if i := strings.IndexRune(kv, '='); i != -1 {
			t[strings.TrimSpace(kv[:i])] = strings.TrimSpace(kv[i+1:])
		} else {
			t[strings.TrimSpace(kv)] = ""
		}
	}
	return t
}

// NewTagsFromRefs creates key-value tags from Softlayer value-only tags.
func NewTagsFromRefs(refs []TagReference) Tags {
	tags := make(Tags, len(refs))
	for _, ref := range refs {
		var k, v string
		k = ref.Tag.Name
		if i := strings.IndexRune(k, ':'); i != -1 {
			v = k[i+1:]
			k = k[:i]
		}
		if k == "" {
			// ignoring empty keys
			continue
		}
		// no guarantee they keys are unique in Softlayer; we keep first
		// encountered, non-empty value
		if oldV, ok := tags[k]; !ok || oldV == "" {
			tags[k] = v
		}
	}
	return tags
}

// Matches gives true when all of the tags are present in t.
func (t Tags) Matches(tags Tags) bool {
	matches := make(map[string]struct{})
	for k, v := range t {
		if val, ok := tags[k]; ok && (val == "" || v == "" || v == val) {
			matches[k] = struct{}{}
		}
	}
	return len(matches) == len(tags)
}

// Ref returns the Softlayer string representation of list of TagReferences.
func (t Tags) Ref() string {
	if len(t) == 0 {
		return ""
	}
	var buf bytes.Buffer
	for k, v := range t {
		fmt.Fprintf(&buf, "%s:%s,", k, v)
	}
	p := buf.Bytes()
	p = p[:len(p)-1] // remove dangling comma
	return string(p)
}

// Copy returns a copy of the tags.
func (t Tags) Copy() Tags {
	tCopy := make(Tags, len(t))
	for k, v := range t {
		tCopy[k] = v
	}
	return tCopy
}

// String gives key-value tags representation.
func (t Tags) String() string {
	if len(t) == 0 {
		return "[]"
	}
	var buf bytes.Buffer
	fmt.Fprint(&buf, "[")
	for k, v := range t {
		fmt.Fprint(&buf, k, "=", v, ",")
	}
	p := buf.Bytes()
	p[len(p)-1] = ']' // replace last dangling commna
	return string(p)
}

// templateMasks represents objectMasks for the Template struct.
var templateMask = ObjectMask((*Template)(nil))

// Template represents a Softlayer's Block_Device_Template resource.
type Template struct {
	ID          int           `json:"id,omitempty"`
	ParentID    int           `json:"parentId,omitempty"`
	GlobalID    string        `json:"globalIdentifier,omitempty"`
	CreateDate  time.Time     `json:"createDate,omitempty"`
	Name        string        `json:"name,omitempty"`
	Note        string        `json:"note,omitempty"`
	Datacenter  *Datacenter   `json:"datacenter,omitempty"`
	Datacenters []*Datacenter `json:"datacenters,omitempty"`

	Tags        Tags `json:"-"`
	NotTaggable bool `json:"-"`
}

// decode unmarshals tags from description or mark as non taggable when decoding fails.
func (t *Template) decode() {
	if err := json.Unmarshal([]byte(t.Note), &t.Tags); err != nil {
		t.NotTaggable = true
	}
}

// Templates is a convenience type for a list of templates, that supports
// filtering.
type Templates []*Template

func (t Templates) Err() error {
	if len(t) == 0 {
		return errNotFound
	}
	return nil
}

// Parent returns those templates, which have ParentID equal to 0.
func (t Templates) Parent() Templates {
	var parents []*Template
	for _, template := range t {
		if template.ParentID == 0 {
			parents = append(parents, template)
		}
	}
	return parents
}

// ByID filters the templates by ID.
func (t Templates) ByID(id int) Templates {
	if id == 0 {
		return t
	}
	for _, template := range t {
		if template.ID == id {
			return Templates{template}
		}
	}
	return nil
}

// ByName returns the templates, which names matches the given name.
func (t Templates) ByName(name string) (res Templates) {
	if name == "" {
		return t
	}
	for _, template := range t {
		if strings.Contains(template.Name, name) {
			res = append(res, template)
		}
	}
	return res
}

// ByDatacenter returns those templates which are either located
// in the given datacenter or are available in the given datacenter.
func (t Templates) ByDatacenter(datacenter string) (res Templates) {
	if datacenter == "" {
		return t
	}
	for _, template := range t {
		if template.Datacenter != nil && template.Datacenter.Name == datacenter {
			res = append(res, template)
			continue
		}
		for _, d := range template.Datacenters {
			if d.Name == datacenter {
				res = append(res, template)
				break
			}
		}
	}
	return res
}

// ByTags returns those templates, whose tags match fully the given tags.
func (t Templates) ByTags(tags Tags) (res Templates) {
	if len(tags) == 0 {
		return t
	}
	for _, template := range t {
		if template.Tags.Matches(tags) {
			res = append(res, template)
		}
	}
	return res
}

// Filter filters the template by the given filter value.
func (t *Templates) Filter(f *Filter) {
	if !f.Children {
		*t = t.Parent()
	}
	*t = t.ByID(f.ID).
		ByName(f.Name).
		ByDatacenter(f.Datacenter).
		ByTags(f.Tags)
}

// Decode implements the ResourceDecoder interface.
func (t Templates) Decode() {
	for _, template := range t {
		template.decode()
	}
}

// Sorts the templates descending by creation date.
func (t Templates) Len() int           { return len(t) }
func (t Templates) Less(i, j int) bool { return t[i].CreateDate.After(t[j].CreateDate) }
func (t Templates) Swap(i, j int)      { t[i], t[j] = t[j], t[i] }
