package schema

// Link represents a Link description.
type Link struct {
	Title        string  `json:"title,omitempty"`
	Description  string  `json:"description,omitempty"`
	HRef         *HRef   `json:"href,omitempty"`
	Rel          string  `json:"rel,omitempty"`
	Method       string  `json:"method,omitempty"`
	Schema       *Schema `json:"schema,omitempty"`
	TargetSchema *Schema `json:"targetSchema,omitempty"`
}

// Resolve resolve link schema and href.
func (l *Link) Resolve(r *Schema) {
	if l.Schema != nil {
		l.Schema = l.Schema.Resolve(r)
	}
	l.HRef.Resolve(r)
}

// GoType returns Go type for the given schema as string.
func (l *Link) GoType() string {
	return l.Schema.goType(true, false)
}
