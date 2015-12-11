package ibm

import (
	"encoding/json"
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
		if val, ok := tags[k]; ok && (v == "" || v == val) {
			matches[k] = struct{}{}
		}
	}
	return len(matches) == len(t)

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
			return []*Template{template}
		}
	}
	return nil
}

// ByName returns the templates, which names matches the given name.
func (t Templates) ByName(name string) Templates {
	if name == "" {
		return t
	}
	var named []*Template
	for _, template := range t {
		if strings.Contains(template.Name, name) {
			named = append(named, template)
		}
	}
	return named
}

// ByDatacenter returns those templates which are either located
// in the given datacenter or are available in the given datacenter.
func (t Templates) ByDatacenter(datacenter string) Templates {
	if datacenter == "" {
		return t
	}
	var regional []*Template
	for _, template := range t {
		if template.Datacenter != nil && template.Datacenter.Name == datacenter {
			regional = append(regional, template)
			continue
		}
		for _, d := range template.Datacenters {
			if d.Name == datacenter {
				regional = append(regional, template)
				break
			}
		}
	}
	return regional
}

// ByTags returns those templates, whose tags matches fully the given tags.
func (t Templates) ByTags(tags Tags) Templates {
	if len(tags) == 0 {
		return t
	}
	var tagged []*Template
	for _, template := range t {
		if tags.Matches(template.Tags) {
			tagged = append(tagged, template)
		}
	}
	return tagged
}

// Filter filters the template by the given filter value.
func (t Templates) Filter(f *Filter) Templates {
	if f == nil {
		return t
	}
	if !f.Children {
		t = t.Parent()
	}
	return t.ByID(f.ID).ByName(f.Name).ByDatacenter(f.Datacenter).ByTags(f.Tags)
}

type byCreateDateDesc []*Template

func (p byCreateDateDesc) Len() int           { return len(p) }
func (p byCreateDateDesc) Less(i, j int) bool { return p[i].CreateDate.After(p[i].CreateDate) }
func (p byCreateDateDesc) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }
