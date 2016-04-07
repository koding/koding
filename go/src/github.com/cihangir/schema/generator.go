package schema

// Generator holds arbitary data about a generator's settings
type Generator map[string]interface{}

// Generators acts as a container for generators
type Generators []map[string]Generator

// Get returns the setting data, if exits
func (g *Generator) Get(key string) interface{} {
	d, ok := (*g)[key]
	if !ok {
		return nil
	}

	return d
}

// GetWithDefault returns the existing setting if exists, if not returns the
// given setting
func (g *Generator) GetWithDefault(key string, def interface{}) interface{} {
	d, ok := (*g)[key]
	if !ok {
		return def
	}

	return d
}

// SetNX sets a value to the settings if only value does not exists
func (g *Generator) SetNX(key string, val interface{}) {
	_, ok := (*g)[key]
	if !ok {
		g.Set(key, val)
	}
}

// Set sets a value to the settings, overrides any previous value
func (g *Generator) Set(key string, val interface{}) {
	if *g == nil {
		*g = make(map[string]interface{})
	}
	(*g)[key] = val
}

// Has checks if the given generator exists
func (g Generators) Has(s string) bool {
	_, has := g.Get(s)
	return has
}

// Get returns the generator with given key
func (g *Generators) Get(s string) (Generator, bool) {
	for _, m := range *g {
		if d, ok := m[s]; ok {
			return d, ok
		}
	}

	return nil, false
}
