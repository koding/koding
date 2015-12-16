package sl

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// Datacenter represents a Softlayer datacenter.
type Datacenter struct {
	ID       int    `json:"id,omitempty"`
	Name     string `json:"name,omitempty"`
	StatusID int    `json:"statusId,omitempty"`
}

// String implements the fmt.Stringer interface.
func (d *Datacenter) String() string {
	return d.Name
}

// Tags represents the resource tags.
//
// If Softlayer does not support tagging the resource, it's
// emulated by keeping stringified JSON of the tags
// in the Description, Comment or Note field of the resource.
type Tags map[string]string

// Matches
func (t Tags) Matches(tags Tags) bool {
	matches := make(map[string]struct{})
	for k, v := range t {
		if val, ok := tags[k]; ok && (val == "" || v == "" || v == val) {
			matches[k] = struct{}{}
		}
	}
	return len(matches) == len(tags)

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

// TemplateMasks represents objectMasks for the Template struct.
//
// TODO(rjeczalik): infer the list from JSON tags
var TemplateMasks = []string{
	"id",
	"parentId",
	"globalIdentifier",
	"createDate",
	"name",
	"note",
	"datacenter",
	"datacenters",
}

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

// Templates is a conveniance type for a list of templates, that supports
// filtering.
type Templates []*Template

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
func (t Templates) Filter(f *Filter) Templates {
	if f == nil {
		return t
	}
	if !f.Children {
		t = t.Parent()
	}
	return t.ByID(f.ID).
		ByName(f.Name).
		ByDatacenter(f.Datacenter).
		ByTags(f.Tags)
}

type byCreateDateDesc []*Template

func (p byCreateDateDesc) Len() int           { return len(p) }
func (p byCreateDateDesc) Less(i, j int) bool { return p[i].CreateDate.After(p[j].CreateDate) }
func (p byCreateDateDesc) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }
