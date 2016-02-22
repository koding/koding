package smtpapi

import (
	"bytes"
	"encoding/json"
	"fmt"
	"unicode/utf16"
)

const Version = "0.4.0"

// SMTPAPIHeader will be used to set up X-SMTPAPI params
type SMTPAPIHeader struct {
	To         []string            `json:"to,omitempty"`
	Sub        map[string][]string `json:"sub,omitempty"`
	Section    map[string]string   `json:"section,omitempty"`
	Category   []string            `json:"category,omitempty"`
	UniqueArgs map[string]string   `json:"unique_args,omitempty"`
	Filters    map[string]Filter   `json:"filters,omitempty"`
	ASMGroupID int                 `json:"asm_group_id,omitempty"`
	SendAt     int64               `json:"send_at,omitempty"`
	SendEachAt []int64             `json:"send_each_at,omitempty"`
	IpPool     string              `json:"ip_pool,omitempty"`
}

// Filter represents an App/Filter and its settings
type Filter struct {
	Settings map[string]string `json:"settings,omitempty"`
}

// NewSMTPAPIHeader creates a new header struct
func NewSMTPAPIHeader() *SMTPAPIHeader {
	return &SMTPAPIHeader{}
}

// AddTo appends a single email to the To header
func (h *SMTPAPIHeader) AddTo(email string) {
	h.To = append(h.To, email)
}

// AddTos appends multiple emails to the To header
func (h *SMTPAPIHeader) AddTos(emails []string) {
	for i := 0; i < len(emails); i++ {
		h.AddTo(emails[i])
	}
}

// SetTos sets the value of the To header
func (h *SMTPAPIHeader) SetTos(emails []string) {
	h.To = emails
}

// AddSubstitution adds a new substitution to a specific key
func (h *SMTPAPIHeader) AddSubstitution(key, sub string) {
	if h.Sub == nil {
		h.Sub = make(map[string][]string)
	}
	h.Sub[key] = append(h.Sub[key], sub)
}

// AddSubstitutions adds a multiple substitutions to a specific key
func (h *SMTPAPIHeader) AddSubstitutions(key string, subs []string) {
	for i := 0; i < len(subs); i++ {
		h.AddSubstitution(key, subs[i])
	}
}

// SetSubstitutions sets the value of the substitutions on the Sub header
func (h *SMTPAPIHeader) SetSubstitutions(sub map[string][]string) {
	h.Sub = sub
}

// AddSection sets the value for a specific section
func (h *SMTPAPIHeader) AddSection(section, value string) {
	if h.Section == nil {
		h.Section = make(map[string]string)
	}
	h.Section[section] = value
}

// SetSections sets the value for the Section header
func (h *SMTPAPIHeader) SetSections(sections map[string]string) {
	h.Section = sections
}

// AddCategory adds a new category to the Category header
func (h *SMTPAPIHeader) AddCategory(category string) {
	h.Category = append(h.Category, category)
}

// AddCategories adds multiple categories to the Category header
func (h *SMTPAPIHeader) AddCategories(categories []string) {
	for i := 0; i < len(categories); i++ {
		h.AddCategory(categories[i])
	}
}

// SetCategories will set the value of the Categories field
func (h *SMTPAPIHeader) SetCategories(categories []string) {
	h.Category = categories
}

// SetASMGroupID will set the value of the ASMGroupID field
func (h *SMTPAPIHeader) SetASMGroupID(groupID int) {
	h.ASMGroupID = groupID
}

// AddUniqueArg will set the value of a specific argument
func (h *SMTPAPIHeader) AddUniqueArg(arg, value string) {
	if h.UniqueArgs == nil {
		h.UniqueArgs = make(map[string]string)
	}
	h.UniqueArgs[arg] = value
}

// SetUniqueArgs will set the value of the Unique_args header
func (h *SMTPAPIHeader) SetUniqueArgs(args map[string]string) {
	h.UniqueArgs = args
}

// AddFilter will set the specific setting for a filter
func (h *SMTPAPIHeader) AddFilter(filter, setting, value string) {
	if h.Filters == nil {
		h.Filters = make(map[string]Filter)
	}
	if _, ok := h.Filters[filter]; !ok {
		h.Filters[filter] = Filter{
			Settings: make(map[string]string),
		}
	}
	h.Filters[filter].Settings[setting] = value
}

// SetFilter takes in a Filter struct with predetermined settings and sets it for such Filter key
func (h *SMTPAPIHeader) SetFilter(filter string, value *Filter) {
	if h.Filters == nil {
		h.Filters = make(map[string]Filter)
	}
	h.Filters[filter] = *value
}

// SetSendAt takes in a timestamp which determines when the email will be sent
func (h *SMTPAPIHeader) SetSendAt(sendAt int64) {
	h.SendAt = sendAt
}

// AddSendEachAt takes in a timestamp and pushes it into a list Must match length of To emails
func (h *SMTPAPIHeader) AddSendEachAt(sendEachAt int64) {
	h.SendEachAt = append(h.SendEachAt, sendEachAt)
}

// SetSendEachAt takes an array of timestamps. Must match length of To emails
func (h *SMTPAPIHeader) SetSendEachAt(sendEachAt []int64) {
	h.SendEachAt = sendEachAt
}

// SetIpPool takes a strings and sets the IpPool field
func (h *SMTPAPIHeader) SetIpPool(ipPool string) {
	h.IpPool = ipPool
}

// Unicode escape
func escapeUnicode(input string) string {
	//var buffer bytes.Buffer
	buffer := bytes.NewBufferString("")
	for _, r := range input {
		if r > 65535 {
			// surrogate pair
			var r1, r2 = utf16.EncodeRune(r)
			var s = fmt.Sprintf("\\u%x\\u%x", r1, r2)
			buffer.WriteString(s)
		} else if r > 127 {
			var s = fmt.Sprintf("\\u%04x", r)
			buffer.WriteString(s)
		} else {
			var s = fmt.Sprintf("%c", r)
			buffer.WriteString(s)
		}
	}
	return buffer.String()
}

// JSONString returns the representation of the Header
func (h *SMTPAPIHeader) JSONString() (string, error) {
	headers, e := json.Marshal(h)
	return escapeUnicode(string(headers)), e
}
