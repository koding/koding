package models

import (
	"encoding/xml"
)

// used for setting ChangeFrequency value
const (
	Definition_FREQ_ALWAYS  = "always"
	Definition_FREQ_HOURLY  = "hourly"
	Definition_FREQ_DAILY   = "daily"
	Definition_FREQ_WEEKLY  = "weekly"
	Definition_FREQ_MONTHLY = "monthly"
	Definition_FREQ_YEARLY  = "yearly"
	Definition_FREQ_NEVER   = "never"
)

// ItemDefiniton corresponds to url element
type ItemDefinition struct {
	// set element name
	XMLName xml.Name `xml:"url"`
	// location of url
	Location string `xml:"loc"`
	// used for updated elements
	LastModified string `xml:"lastmod,omitempty"`
	// defined with constant frequency values
	ChangeFrequency string `xml:"changefreq,omitempty"`
	// sets priority of the url
	Priority float64 `xml:"priority,omitempty"`
}
