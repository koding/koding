package sl

// datacenterMask represents objectMask Softlayer API value for the Datacenter
// type
var datacenterMask = ObjectMask((*Datacenter)(nil))

// Datacenter represents the SoftLayer_Location_Datacenter model.
type Datacenter struct {
	ID       int              `json:"id,omitempty"`
	Name     string           `json:"name,omitempty"`
	LongName string           `json:"longName,omitempty"`
	Status   LocationStatus   `json:"locationStatus,omitempty"`
	Groups   []LocationGroup  `json:"groups,omitempty"`
	Regions  []LocationRegion `json:"regions,omitempty"`
	Timezone LocaleTimezone   `json:"timezone,omitempty"`
}

// String implements the fmt.Stringer interface.
func (d *Datacenter) String() string {
	return d.Name
}

// LocationGroup represents the SoftLayer_Location_Group model.
type LocationGroup struct {
	ID              int               `json:"id,omitempty"`
	GroupType       LocationGroupType `json:"locationGroupType,omitempty"`
	Name            string            `json:"name,omitempty"`
	Description     string            `json:"description,omitempty"`
	SecurityLevelID int               `json:"securityLevelId,omitempty"`
}

// LocationGroupType represents the SoftLayer_Location_Group_Type model.
type LocationGroupType struct {
	Name string `json:"name,omitempty"`
}

// LocationRegion represents the SoftLayer_Location_Region model.
type LocationRegion struct {
	Description string `json:"description,omitempty"`
	Keyname     string `json:"keyname,omitempty"`
	SortOrder   int    `json:"sortOrder,omitempty"`
}

// LocationStatus represents the SoftLayer_Location_Status model.
type LocationStatus struct {
	ID     int    `json:"id,omitempty"`
	Status string `json:"status,omitempty"` // ACTIVE, PLANNED, RETIRED
}

// LocaleTimezone represents the SoftLayer_Local_Timezone model.
type LocaleTimezone struct {
	ID        int    `json:"id,omitempty"`
	Name      string `json:"name,omitempty"`
	LongName  string `json:"longName,omitempty"`
	ShortName string `json:"shortName,omitempty"`
	Offset    string `json:"offset,omitempty"`
}

// Datacenters is convenience wrapper for slice of datacenters which provides
// filtering capabilities.
type Datacenters []*Datacenter

func (d Datacenters) Err() error {
	if len(d) == 0 {
		return errNotFound
	}
	return nil
}

// ByID filters the datacenters by id.
func (d Datacenters) ByID(id int) Datacenters {
	if id == 0 {
		return d
	}
	for _, datacenter := range d {
		if datacenter.ID == id {
			return Datacenters{datacenter}
		}
	}
	return nil
}

// ByName filters the datacenters by name.
func (d Datacenters) ByName(name string) (res Datacenters) {
	if name == "" {
		return d
	}
	for _, datacenter := range d {
		if datacenter.Name == name {
			res = append(res, datacenter)
		}
	}
	return res
}

// Filter filters the datacenters by the given filter.
func (d *Datacenters) Filter(f *Filter) {
	*d = d.ByID(f.ID).ByName(f.Name)
}

// Sorts the datacenters ascending by name.
func (d Datacenters) Len() int           { return len(d) }
func (d Datacenters) Less(i, j int) bool { return d[i].Name < d[j].Name }
func (d Datacenters) Swap(i, j int)      { d[i], d[j] = d[j], d[i] }
