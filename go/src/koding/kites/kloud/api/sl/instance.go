package sl

import (
	"strings"
	"time"
)

// Attribute represents a single instance attribute.
type Attribute struct {
	Value string `json:"value,omitempty"`
}

// Tag represents a single tag value.
type Tag struct {
	ID       int    `json:"id,omitempty"`
	Name     string `json:"name,omitempty"`
	Internal int    `json:"internal,omitempty"`
}

// TagReference represents a Softlayer tag.
type TagReference struct {
	ID  int `json:"id,omitempty"`
	Tag Tag `json:"tag,omitempty"`
}

// instanceMask represents objectMask for the Instance struct.
var instanceMask = ObjectMask((*Instance)(nil))

// Instance represents a Softlayer_Virtual_Guest resource.
type Instance struct {
	ID            int            `json:"id,omitempty"`
	GlobalID      string         `json:"globalIdentifier,omitempty"`
	Hostname      string         `json:"hostname,omitempty"`
	Domain        string         `json:"domain,omitempty"`
	UUID          string         `json:"uuid,omitempty"`
	CreateDate    time.Time      `json:"createDate,omitempty"`
	Datacenter    *Datacenter    `json:"datacenter,omitempty"`
	Attributes    []Attribute    `json:"attributes,omitempty"`
	SshKeys       []Key          `json:"sshKeys,omitempty"`
	TagReferences []TagReference `json:"tagReferences,omitempty"`

	Tags        Tags `json:"-"`
	NotTaggable bool `json:"-"`
}

func (i *Instance) decode() {
	tags := make(Tags, len(i.TagReferences))
	for _, tag := range i.TagReferences {
		j := strings.IndexRune(tag.Tag.Name, ':')
		if j == -1 {
			i.NotTaggable = true
			return
		}
		key := tag.Tag.Name[:j]
		value := tag.Tag.Name[j+1:]
		tags[key] = value
	}
	i.Tags = tags
}

// Instances is a conveniance type for a list of instances that supports
// filtering.
type Instances []*Instance

// ByID filters the instances by ID.
func (i Instances) ByID(id int) Instances {
	if id == 0 {
		return i
	}
	for _, instance := range i {
		if instance.ID == id {
			return Instances{instance}
		}
	}
	return nil
}

// ByTags filters the instances by tags.
func (i Instances) ByTags(tags Tags) (res Instances) {
	if len(tags) == 0 {
		return i
	}
	for _, instance := range i {
		if instance.Tags.Matches(tags) {
			res = append(res, instance)
		}
	}
	return res
}

// Filter applies the given filter to instances.
func (i *Instances) Filter(f *Filter) {
	*i = i.ByID(f.ID).ByTags(f.Tags)
}

// Decode implements the ResourceDecoder interface.
func (i Instances) Decode() {
	for _, instance := range i {
		instance.decode()
	}
}

// Sorts the instances by creation date.
func (i Instances) Len() int           { return len(i) }
func (i Instances) Less(j, k int) bool { return i[j].CreateDate.After(i[k].CreateDate) }
func (i Instances) Swap(j, k int)      { i[j], i[k] = i[k], i[j] }
