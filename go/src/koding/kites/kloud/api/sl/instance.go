package sl

import "time"

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
var instanceMask = ObjectMask((*Instance)(nil), "networkVlans.virtualGuests")

// Instance represents a Softlayer_Virtual_Guest resource.
type Instance struct {
	ID            int            `json:"id,omitempty"`
	GlobalID      string         `json:"globalIdentifier,omitempty"`
	Hostname      string         `json:"hostname,omitempty"`
	Domain        string         `json:"domain,omitempty"`
	UUID          string         `json:"uuid,omitempty"`
	IPAddress     string         `json:"primaryIpAddress,omitempty"`
	CreateDate    time.Time      `json:"createDate,omitempty"`
	Datacenter    Datacenter     `json:"datacenter,omitempty"`
	Attributes    []Attribute    `json:"attributes,omitempty"`
	SshKeys       []Key          `json:"sshKeys,omitempty"`
	TagReferences []TagReference `json:"tagReferences,omitempty"`
	VLANs         []VLAN         `json:"networkVlans,omitempty"`
	Firewall      Firewall       `json:"firewallServiceComponent,omitempty"`

	Tags        Tags `json:"-"`
	NotTaggable bool `json:"-"`
}

func (i *Instance) decode() {
	i.Tags = NewTagsFromRefs(i.TagReferences)
}

// instanceEntryMask represents objectMask for the InstanceEntry struct.
var instanceEntryMask = ObjectMask((*InstanceEntry)(nil))

// InstanceEntry is stripped down definition of Instance including only
// hostname and tags. It's used to speed up query times, partially it
// works around lack of pagination.
//
// Rationale is that full list of 1000k Instances takes at minimum
// several minutes to process (if it does not time out), the output
// payload containing 15MB of data. Querying for entries takes
// 10x less time and space (~10s and 0.85MB).
type InstanceEntry struct {
	ID            int            `json:"id,omitempty"`
	Hostname      string         `json:"hostname,omitempty"`
	TagReferences []TagReference `json:"tagReferences,omitempty"`

	Tags Tags `json:"-"`
}

func (e *InstanceEntry) decode() {
	e.Tags = NewTagsFromRefs(e.TagReferences)
}

// Instances is a convenience type for a list of instances that supports
// filtering.
type Instances []*Instance

func (i Instances) Err() error {
	if len(i) == 0 {
		return errNotFound
	}
	return nil
}

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

// ByHostname filters the instances by their hostname.
func (i Instances) ByHostname(hostname string) (res Instances) {
	if hostname == "" {
		return i
	}
	for _, instance := range i {
		if instance.Hostname == hostname {
			res = append(res, instance)
		}
	}
	return res
}

// Filter applies the given filter to instances.
func (i *Instances) Filter(f *Filter) {
	*i = i.ByID(f.ID).ByHostname(f.Hostname).ByTags(f.Tags)
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

// InstanceEntries is a convenience type for a list of instance entries
// that support filtering.
type InstanceEntries []*InstanceEntry

func (e InstanceEntries) Err() error {
	if len(e) == 0 {
		return errNotFound
	}
	return nil
}

// ByID filters the instance entries by ID.
func (e InstanceEntries) ByID(id int) InstanceEntries {
	if id == 0 {
		return e
	}
	for _, entry := range e {
		if entry.ID == id {
			return InstanceEntries{entry}
		}
	}
	return nil
}

// ByTags filters the instance entries by tags.
func (e InstanceEntries) ByTags(tags Tags) (res InstanceEntries) {
	if len(tags) == 0 {
		return e
	}
	for _, entry := range e {
		if entry.Tags.Matches(tags) {
			res = append(res, entry)
		}
	}
	return res
}

// ByHostname filters the instance entries by their hostname.
func (e InstanceEntries) ByHostname(hostname string) (res InstanceEntries) {
	if hostname == "" {
		return e
	}
	for _, entry := range e {
		if entry.Hostname == hostname {
			res = append(res, entry)
		}
	}
	return res
}

// Filter applies the given filter to instance entries.
func (e *InstanceEntries) Filter(f *Filter) {
	*e = e.ByID(f.ID).ByHostname(f.Hostname).ByTags(f.Tags)
}

// Decode implements the ResourceDecoder interface.
func (e InstanceEntries) Decode() {
	for _, entry := range e {
		entry.decode()
	}
}

// Sorts the instance entries by id.
func (e InstanceEntries) Len() int           { return len(e) }
func (e InstanceEntries) Less(i, j int) bool { return e[i].ID > e[j].ID }
func (e InstanceEntries) Swap(i, j int)      { e[i], e[j] = e[j], e[i] }
