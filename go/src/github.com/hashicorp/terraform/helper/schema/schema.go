// schema is a high-level framework for easily writing new providers
// for Terraform. Usage of schema is recommended over attempting to write
// to the low-level plugin interfaces manually.
//
// schema breaks down provider creation into simple CRUD operations for
// resources. The logic of diffing, destroying before creating, updating
// or creating, etc. is all handled by the framework. The plugin author
// only needs to implement a configuration schema and the CRUD operations and
// everything else is meant to just work.
//
// A good starting point is to view the Provider structure.
package schema

import (
	"fmt"
	"os"
	"reflect"
	"sort"
	"strconv"
	"strings"

	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/mapstructure"
)

// Schema is used to describe the structure of a value.
//
// Read the documentation of the struct elements for important details.
type Schema struct {
	// Type is the type of the value and must be one of the ValueType values.
	//
	// This type not only determines what type is expected/valid in configuring
	// this value, but also what type is returned when ResourceData.Get is
	// called. The types returned by Get are:
	//
	//   TypeBool - bool
	//   TypeInt - int
	//   TypeFloat - float64
	//   TypeString - string
	//   TypeList - []interface{}
	//   TypeMap - map[string]interface{}
	//   TypeSet - *schema.Set
	//
	Type ValueType

	// If one of these is set, then this item can come from the configuration.
	// Both cannot be set. If Optional is set, the value is optional. If
	// Required is set, the value is required.
	//
	// One of these must be set if the value is not computed. That is:
	// value either comes from the config, is computed, or is both.
	Optional bool
	Required bool

	// If this is non-nil, then this will be a default value that is used
	// when this item is not set in the configuration/state.
	//
	// DefaultFunc can be specified if you want a dynamic default value.
	// Only one of Default or DefaultFunc can be set.
	//
	// If Required is true above, then Default cannot be set. DefaultFunc
	// can be set with Required. If the DefaultFunc returns nil, then there
	// will be no default and the user will be asked to fill it in.
	//
	// If either of these is set, then the user won't be asked for input
	// for this key if the default is not nil.
	Default     interface{}
	DefaultFunc SchemaDefaultFunc

	// Description is used as the description for docs or asking for user
	// input. It should be relatively short (a few sentences max) and should
	// be formatted to fit a CLI.
	Description string

	// InputDefault is the default value to use for when inputs are requested.
	// This differs from Default in that if Default is set, no input is
	// asked for. If Input is asked, this will be the default value offered.
	InputDefault string

	// The fields below relate to diffs.
	//
	// If Computed is true, then the result of this value is computed
	// (unless specified by config) on creation.
	//
	// If ForceNew is true, then a change in this resource necessitates
	// the creation of a new resource.
	//
	// StateFunc is a function called to change the value of this before
	// storing it in the state (and likewise before comparing for diffs).
	// The use for this is for example with large strings, you may want
	// to simply store the hash of it.
	Computed  bool
	ForceNew  bool
	StateFunc SchemaStateFunc

	// The following fields are only set for a TypeList or TypeSet Type.
	//
	// Elem must be either a *Schema or a *Resource only if the Type is
	// TypeList, and represents what the element type is. If it is *Schema,
	// the element type is just a simple value. If it is *Resource, the
	// element type is a complex structure, potentially with its own lifecycle.
	Elem interface{}

	// The following fields are only valid for a TypeSet type.
	//
	// Set defines a function to determine the unique ID of an item so that
	// a proper set can be built.
	Set SchemaSetFunc

	// ComputedWhen is a set of queries on the configuration. Whenever any
	// of these things is changed, it will require a recompute (this requires
	// that Computed is set to true).
	//
	// NOTE: This currently does not work.
	ComputedWhen []string

	// ConflictsWith is a set of schema keys that conflict with this schema
	ConflictsWith []string

	// When Deprecated is set, this attribute is deprecated.
	//
	// A deprecated field still works, but will probably stop working in near
	// future. This string is the message shown to the user with instructions on
	// how to address the deprecation.
	Deprecated string

	// When Removed is set, this attribute has been removed from the schema
	//
	// Removed attributes can be left in the Schema to generate informative error
	// messages for the user when they show up in resource configurations.
	// This string is the message shown to the user with instructions on
	// what do to about the removed attribute.
	Removed string
}

// SchemaDefaultFunc is a function called to return a default value for
// a field.
type SchemaDefaultFunc func() (interface{}, error)

// EnvDefaultFunc is a helper function that returns the value of the
// given environment variable, if one exists, or the default value
// otherwise.
func EnvDefaultFunc(k string, dv interface{}) SchemaDefaultFunc {
	return func() (interface{}, error) {
		if v := os.Getenv(k); v != "" {
			return v, nil
		}

		return dv, nil
	}
}

// MultiEnvDefaultFunc is a helper function that returns the value of the first
// environment variable in the given list that returns a non-empty value. If
// none of the environment variables return a value, the default value is
// returned.
func MultiEnvDefaultFunc(ks []string, dv interface{}) SchemaDefaultFunc {
	return func() (interface{}, error) {
		for _, k := range ks {
			if v := os.Getenv(k); v != "" {
				return v, nil
			}
		}
		return dv, nil
	}
}

// SchemaSetFunc is a function that must return a unique ID for the given
// element. This unique ID is used to store the element in a hash.
type SchemaSetFunc func(interface{}) int

// SchemaStateFunc is a function used to convert some type to a string
// to be stored in the state.
type SchemaStateFunc func(interface{}) string

func (s *Schema) GoString() string {
	return fmt.Sprintf("*%#v", *s)
}

// Returns a default value for this schema by either reading Default or
// evaluating DefaultFunc. If neither of these are defined, returns nil.
func (s *Schema) DefaultValue() (interface{}, error) {
	if s.Default != nil {
		return s.Default, nil
	}

	if s.DefaultFunc != nil {
		defaultValue, err := s.DefaultFunc()
		if err != nil {
			return nil, fmt.Errorf("error loading default: %s", err)
		}
		return defaultValue, nil
	}

	return nil, nil
}

func (s *Schema) finalizeDiff(
	d *terraform.ResourceAttrDiff) *terraform.ResourceAttrDiff {
	if d == nil {
		return d
	}

	if d.NewRemoved {
		return d
	}

	if s.Computed {
		if d.Old != "" && d.New == "" {
			// This is a computed value with an old value set already,
			// just let it go.
			return nil
		}

		if d.New == "" {
			// Computed attribute without a new value set
			d.NewComputed = true
		}
	}

	if s.ForceNew {
		// Force new, set it to true in the diff
		d.RequiresNew = true
	}

	return d
}

// schemaMap is a wrapper that adds nice functions on top of schemas.
type schemaMap map[string]*Schema

// Data returns a ResourceData for the given schema, state, and diff.
//
// The diff is optional.
func (m schemaMap) Data(
	s *terraform.InstanceState,
	d *terraform.InstanceDiff) (*ResourceData, error) {
	return &ResourceData{
		schema: m,
		state:  s,
		diff:   d,
	}, nil
}

// Diff returns the diff for a resource given the schema map,
// state, and configuration.
func (m schemaMap) Diff(
	s *terraform.InstanceState,
	c *terraform.ResourceConfig) (*terraform.InstanceDiff, error) {
	result := new(terraform.InstanceDiff)
	result.Attributes = make(map[string]*terraform.ResourceAttrDiff)

	d := &ResourceData{
		schema: m,
		state:  s,
		config: c,
	}

	for k, schema := range m {
		err := m.diff(k, schema, result, d, false)
		if err != nil {
			return nil, err
		}
	}

	// If the diff requires a new resource, then we recompute the diff
	// so we have the complete new resource diff, and preserve the
	// RequiresNew fields where necessary so the user knows exactly what
	// caused that.
	if result.RequiresNew() {
		// Create the new diff
		result2 := new(terraform.InstanceDiff)
		result2.Attributes = make(map[string]*terraform.ResourceAttrDiff)

		// Reset the data to not contain state. We have to call init()
		// again in order to reset the FieldReaders.
		d.state = nil
		d.init()

		// Perform the diff again
		for k, schema := range m {
			err := m.diff(k, schema, result2, d, false)
			if err != nil {
				return nil, err
			}
		}

		// Force all the fields to not force a new since we know what we
		// want to force new.
		for k, attr := range result2.Attributes {
			if attr == nil {
				continue
			}

			if attr.RequiresNew {
				attr.RequiresNew = false
			}

			if s != nil {
				attr.Old = s.Attributes[k]
			}
		}

		// Now copy in all the requires new diffs...
		for k, attr := range result.Attributes {
			if attr == nil {
				continue
			}

			newAttr, ok := result2.Attributes[k]
			if !ok {
				newAttr = attr
			}

			if attr.RequiresNew {
				newAttr.RequiresNew = true
			}

			result2.Attributes[k] = newAttr
		}

		// And set the diff!
		result = result2
	}

	// Remove any nil diffs just to keep things clean
	for k, v := range result.Attributes {
		if v == nil {
			delete(result.Attributes, k)
		}
	}

	// Go through and detect all of the ComputedWhens now that we've
	// finished the diff.
	// TODO

	if result.Empty() {
		// If we don't have any diff elements, just return nil
		return nil, nil
	}

	return result, nil
}

// Input implements the terraform.ResourceProvider method by asking
// for input for required configuration keys that don't have a value.
func (m schemaMap) Input(
	input terraform.UIInput,
	c *terraform.ResourceConfig) (*terraform.ResourceConfig, error) {
	keys := make([]string, 0, len(m))
	for k, _ := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	for _, k := range keys {
		v := m[k]

		// Skip things that don't require config, if that is even valid
		// for a provider schema.
		if !v.Required && !v.Optional {
			continue
		}

		// Skip things that have a value of some sort already
		if _, ok := c.Raw[k]; ok {
			continue
		}

		// Skip if it has a default value
		defaultValue, err := v.DefaultValue()
		if err != nil {
			return nil, fmt.Errorf("%s: error loading default: %s", k, err)
		}
		if defaultValue != nil {
			continue
		}

		var value interface{}
		switch v.Type {
		case TypeBool, TypeInt, TypeFloat, TypeSet:
			continue
		case TypeString:
			value, err = m.inputString(input, k, v)
		default:
			panic(fmt.Sprintf("Unknown type for input: %#v", v.Type))
		}

		if err != nil {
			return nil, fmt.Errorf(
				"%s: %s", k, err)
		}

		c.Config[k] = value
	}

	return c, nil
}

// Validate validates the configuration against this schema mapping.
func (m schemaMap) Validate(c *terraform.ResourceConfig) ([]string, []error) {
	return m.validateObject("", m, c)
}

// InternalValidate validates the format of this schema. This should be called
// from a unit test (and not in user-path code) to verify that a schema
// is properly built.
func (m schemaMap) InternalValidate(topSchemaMap schemaMap) error {
	if topSchemaMap == nil {
		topSchemaMap = m
	}
	for k, v := range m {
		if v.Type == TypeInvalid {
			return fmt.Errorf("%s: Type must be specified", k)
		}

		if v.Optional && v.Required {
			return fmt.Errorf("%s: Optional or Required must be set, not both", k)
		}

		if v.Required && v.Computed {
			return fmt.Errorf("%s: Cannot be both Required and Computed", k)
		}

		if !v.Required && !v.Optional && !v.Computed {
			return fmt.Errorf("%s: One of optional, required, or computed must be set", k)
		}

		if v.Computed && v.Default != nil {
			return fmt.Errorf("%s: Default must be nil if computed", k)
		}

		if v.Required && v.Default != nil {
			return fmt.Errorf("%s: Default cannot be set with Required", k)
		}

		if len(v.ComputedWhen) > 0 && !v.Computed {
			return fmt.Errorf("%s: ComputedWhen can only be set with Computed", k)
		}

		if len(v.ConflictsWith) > 0 && v.Required {
			return fmt.Errorf("%s: ConflictsWith cannot be set with Required", k)
		}

		if len(v.ConflictsWith) > 0 {
			for _, key := range v.ConflictsWith {
				parts := strings.Split(key, ".")
				sm := topSchemaMap
				var target *Schema
				for _, part := range parts {
					// Skip index fields
					if _, err := strconv.Atoi(part); err == nil {
						continue
					}

					var ok bool
					if target, ok = sm[part]; !ok {
						return fmt.Errorf("%s: ConflictsWith references unknown attribute (%s)", k, key)
					}

					if subResource, ok := target.Elem.(*Resource); ok {
						sm = schemaMap(subResource.Schema)
					}
				}
				if target == nil {
					return fmt.Errorf("%s: ConflictsWith cannot find target attribute (%s), sm: %#v", k, key, sm)
				}
				if target.Required {
					return fmt.Errorf("%s: ConflictsWith cannot contain Required attribute (%s)", k, key)
				}

				if target.Computed || len(target.ComputedWhen) > 0 {
					return fmt.Errorf("%s: ConflictsWith cannot contain Computed(When) attribute (%s)", k, key)
				}
			}
		}

		if v.Type == TypeList || v.Type == TypeSet {
			if v.Elem == nil {
				return fmt.Errorf("%s: Elem must be set for lists", k)
			}

			if v.Default != nil {
				return fmt.Errorf("%s: Default is not valid for lists or sets", k)
			}

			if v.Type == TypeList && v.Set != nil {
				return fmt.Errorf("%s: Set can only be set for TypeSet", k)
			} else if v.Type == TypeSet && v.Set == nil {
				return fmt.Errorf("%s: Set must be set", k)
			}

			switch t := v.Elem.(type) {
			case *Resource:
				if err := t.InternalValidate(topSchemaMap); err != nil {
					return err
				}
			case *Schema:
				bad := t.Computed || t.Optional || t.Required
				if bad {
					return fmt.Errorf(
						"%s: Elem must have only Type set", k)
				}
			}
		}
	}

	return nil
}

func (m schemaMap) diff(
	k string,
	schema *Schema,
	diff *terraform.InstanceDiff,
	d *ResourceData,
	all bool) error {
	var err error
	switch schema.Type {
	case TypeBool, TypeInt, TypeFloat, TypeString:
		err = m.diffString(k, schema, diff, d, all)
	case TypeList:
		err = m.diffList(k, schema, diff, d, all)
	case TypeMap:
		err = m.diffMap(k, schema, diff, d, all)
	case TypeSet:
		err = m.diffSet(k, schema, diff, d, all)
	default:
		err = fmt.Errorf("%s: unknown type %#v", k, schema.Type)
	}

	return err
}

func (m schemaMap) diffList(
	k string,
	schema *Schema,
	diff *terraform.InstanceDiff,
	d *ResourceData,
	all bool) error {
	o, n, _, computedList := d.diffChange(k)
	if computedList {
		n = nil
	}
	nSet := n != nil

	// If we have an old value and no new value is set or will be
	// computed once all variables can be interpolated and we're
	// computed, then nothing has changed.
	if o != nil && n == nil && !computedList && schema.Computed {
		return nil
	}

	if o == nil {
		o = []interface{}{}
	}
	if n == nil {
		n = []interface{}{}
	}
	if s, ok := o.(*Set); ok {
		o = s.List()
	}
	if s, ok := n.(*Set); ok {
		n = s.List()
	}
	os := o.([]interface{})
	vs := n.([]interface{})

	// If the new value was set, and the two are equal, then we're done.
	// We have to do this check here because sets might be NOT
	// reflect.DeepEqual so we need to wait until we get the []interface{}
	if !all && nSet && reflect.DeepEqual(os, vs) {
		return nil
	}

	// Get the counts
	oldLen := len(os)
	newLen := len(vs)
	oldStr := strconv.FormatInt(int64(oldLen), 10)

	// If the whole list is computed, then say that the # is computed
	if computedList {
		diff.Attributes[k+".#"] = &terraform.ResourceAttrDiff{
			Old:         oldStr,
			NewComputed: true,
		}
		return nil
	}

	// If the counts are not the same, then record that diff
	changed := oldLen != newLen
	computed := oldLen == 0 && newLen == 0 && schema.Computed
	if changed || computed || all {
		countSchema := &Schema{
			Type:     TypeInt,
			Computed: schema.Computed,
			ForceNew: schema.ForceNew,
		}

		newStr := ""
		if !computed {
			newStr = strconv.FormatInt(int64(newLen), 10)
		} else {
			oldStr = ""
		}

		diff.Attributes[k+".#"] = countSchema.finalizeDiff(&terraform.ResourceAttrDiff{
			Old: oldStr,
			New: newStr,
		})
	}

	// Figure out the maximum
	maxLen := oldLen
	if newLen > maxLen {
		maxLen = newLen
	}

	switch t := schema.Elem.(type) {
	case *Resource:
		// This is a complex resource
		for i := 0; i < maxLen; i++ {
			for k2, schema := range t.Schema {
				subK := fmt.Sprintf("%s.%d.%s", k, i, k2)
				err := m.diff(subK, schema, diff, d, all)
				if err != nil {
					return err
				}
			}
		}
	case *Schema:
		// Copy the schema so that we can set Computed/ForceNew from
		// the parent schema (the TypeList).
		t2 := *t
		t2.ForceNew = schema.ForceNew

		// This is just a primitive element, so go through each and
		// just diff each.
		for i := 0; i < maxLen; i++ {
			subK := fmt.Sprintf("%s.%d", k, i)
			err := m.diff(subK, &t2, diff, d, all)
			if err != nil {
				return err
			}
		}
	default:
		return fmt.Errorf("%s: unknown element type (internal)", k)
	}

	return nil
}

func (m schemaMap) diffMap(
	k string,
	schema *Schema,
	diff *terraform.InstanceDiff,
	d *ResourceData,
	all bool) error {
	prefix := k + "."

	// First get all the values from the state
	var stateMap, configMap map[string]string
	o, n, _, nComputed := d.diffChange(k)
	if err := mapstructure.WeakDecode(o, &stateMap); err != nil {
		return fmt.Errorf("%s: %s", k, err)
	}
	if err := mapstructure.WeakDecode(n, &configMap); err != nil {
		return fmt.Errorf("%s: %s", k, err)
	}

	// Keep track of whether the state _exists_ at all prior to clearing it
	stateExists := o != nil

	// Delete any count values, since we don't use those
	delete(configMap, "#")
	delete(stateMap, "#")

	// Check if the number of elements has changed.
	oldLen, newLen := len(stateMap), len(configMap)
	changed := oldLen != newLen
	if oldLen != 0 && newLen == 0 && schema.Computed {
		changed = false
	}

	// It is computed if we have no old value, no new value, the schema
	// says it is computed, and it didn't exist in the state before. The
	// last point means: if it existed in the state, even empty, then it
	// has already been computed.
	computed := oldLen == 0 && newLen == 0 && schema.Computed && !stateExists

	// If the count has changed or we're computed, then add a diff for the
	// count. "nComputed" means that the new value _contains_ a value that
	// is computed. We don't do granular diffs for this yet, so we mark the
	// whole map as computed.
	if changed || computed || nComputed {
		countSchema := &Schema{
			Type:     TypeInt,
			Computed: schema.Computed || nComputed,
			ForceNew: schema.ForceNew,
		}

		oldStr := strconv.FormatInt(int64(oldLen), 10)
		newStr := ""
		if !computed && !nComputed {
			newStr = strconv.FormatInt(int64(newLen), 10)
		} else {
			oldStr = ""
		}

		diff.Attributes[k+".#"] = countSchema.finalizeDiff(
			&terraform.ResourceAttrDiff{
				Old: oldStr,
				New: newStr,
			},
		)
	}

	// If the new map is nil and we're computed, then ignore it.
	if n == nil && schema.Computed {
		return nil
	}

	// Now we compare, preferring values from the config map
	for k, v := range configMap {
		old, ok := stateMap[k]
		delete(stateMap, k)

		if old == v && ok && !all {
			continue
		}

		diff.Attributes[prefix+k] = schema.finalizeDiff(&terraform.ResourceAttrDiff{
			Old: old,
			New: v,
		})
	}
	for k, v := range stateMap {
		diff.Attributes[prefix+k] = schema.finalizeDiff(&terraform.ResourceAttrDiff{
			Old:        v,
			NewRemoved: true,
		})
	}

	return nil
}

func (m schemaMap) diffSet(
	k string,
	schema *Schema,
	diff *terraform.InstanceDiff,
	d *ResourceData,
	all bool) error {
	o, n, _, computedSet := d.diffChange(k)
	if computedSet {
		n = nil
	}
	nSet := n != nil

	// If we have an old value and no new value is set or will be
	// computed once all variables can be interpolated and we're
	// computed, then nothing has changed.
	if o != nil && n == nil && !computedSet && schema.Computed {
		return nil
	}

	if o == nil {
		o = &Set{F: schema.Set}
	}
	if n == nil {
		n = &Set{F: schema.Set}
	}
	os := o.(*Set)
	ns := n.(*Set)

	// If the new value was set, compare the listCode's to determine if
	// the two are equal. Comparing listCode's instead of the actuall values
	// is needed because there could be computed values in the set which
	// would result in false positives while comparing.
	if !all && nSet && reflect.DeepEqual(os.listCode(), ns.listCode()) {
		return nil
	}

	// Get the counts
	oldLen := os.Len()
	newLen := ns.Len()
	oldStr := strconv.Itoa(oldLen)
	newStr := strconv.Itoa(newLen)

	// If the set computed then say that the # is computed
	if computedSet || (schema.Computed && !nSet) {
		// If # already exists, equals 0 and no new set is supplied, there
		// is nothing to record in the diff
		count, ok := d.GetOk(k + ".#")
		if ok && count.(int) == 0 && !nSet && !computedSet {
			return nil
		}

		// Set the count but make sure that if # does not exist, we don't
		// use the zeroed value
		countStr := strconv.Itoa(count.(int))
		if !ok {
			countStr = ""
		}

		diff.Attributes[k+".#"] = &terraform.ResourceAttrDiff{
			Old:         countStr,
			NewComputed: true,
		}
		return nil
	}

	// If the counts are not the same, then record that diff
	changed := oldLen != newLen
	if changed || all {
		countSchema := &Schema{
			Type:     TypeInt,
			Computed: schema.Computed,
			ForceNew: schema.ForceNew,
		}

		diff.Attributes[k+".#"] = countSchema.finalizeDiff(&terraform.ResourceAttrDiff{
			Old: oldStr,
			New: newStr,
		})
	}

	for _, code := range ns.listCode() {
		// If the code is negative (first character is -) then
		// replace it with "~" for our computed set stuff.
		codeStr := strconv.Itoa(code)
		if codeStr[0] == '-' {
			codeStr = string('~') + codeStr[1:]
		}

		switch t := schema.Elem.(type) {
		case *Resource:
			// This is a complex resource
			for k2, schema := range t.Schema {
				subK := fmt.Sprintf("%s.%s.%s", k, codeStr, k2)
				err := m.diff(subK, schema, diff, d, true)
				if err != nil {
					return err
				}
			}
		case *Schema:
			// Copy the schema so that we can set Computed/ForceNew from
			// the parent schema (the TypeSet).
			t2 := *t
			t2.ForceNew = schema.ForceNew

			// This is just a primitive element, so go through each and
			// just diff each.
			subK := fmt.Sprintf("%s.%s", k, codeStr)
			err := m.diff(subK, &t2, diff, d, true)
			if err != nil {
				return err
			}
		default:
			return fmt.Errorf("%s: unknown element type (internal)", k)
		}
	}

	return nil
}

func (m schemaMap) diffString(
	k string,
	schema *Schema,
	diff *terraform.InstanceDiff,
	d *ResourceData,
	all bool) error {
	var originalN interface{}
	var os, ns string
	o, n, _, _ := d.diffChange(k)
	if schema.StateFunc != nil {
		originalN = n
		n = schema.StateFunc(n)
	}
	nraw := n
	if nraw == nil && o != nil {
		nraw = schema.Type.Zero()
	}
	if err := mapstructure.WeakDecode(o, &os); err != nil {
		return fmt.Errorf("%s: %s", k, err)
	}
	if err := mapstructure.WeakDecode(nraw, &ns); err != nil {
		return fmt.Errorf("%s: %s", k, err)
	}

	if os == ns && !all {
		// They're the same value. If there old value is not blank or we
		// have an ID, then return right away since we're already setup.
		if os != "" || d.Id() != "" {
			return nil
		}

		// Otherwise, only continue if we're computed
		if !schema.Computed {
			return nil
		}
	}

	removed := false
	if o != nil && n == nil {
		removed = true
	}
	if removed && schema.Computed {
		return nil
	}

	diff.Attributes[k] = schema.finalizeDiff(&terraform.ResourceAttrDiff{
		Old:        os,
		New:        ns,
		NewExtra:   originalN,
		NewRemoved: removed,
	})

	return nil
}

func (m schemaMap) inputString(
	input terraform.UIInput,
	k string,
	schema *Schema) (interface{}, error) {
	result, err := input.Input(&terraform.InputOpts{
		Id:          k,
		Query:       k,
		Description: schema.Description,
		Default:     schema.InputDefault,
	})

	return result, err
}

func (m schemaMap) validate(
	k string,
	schema *Schema,
	c *terraform.ResourceConfig) ([]string, []error) {
	raw, ok := c.Get(k)
	if !ok && schema.DefaultFunc != nil {
		// We have a dynamic default. Check if we have a value.
		var err error
		raw, err = schema.DefaultFunc()
		if err != nil {
			return nil, []error{fmt.Errorf(
				"%q, error loading default: %s", k, err)}
		}

		// We're okay as long as we had a value set
		ok = raw != nil
	}
	if !ok {
		if schema.Required {
			return nil, []error{fmt.Errorf(
				"%q: required field is not set", k)}
		}

		return nil, nil
	}

	if !schema.Required && !schema.Optional {
		// This is a computed-only field
		return nil, []error{fmt.Errorf(
			"%q: this field cannot be set", k)}
	}

	err := m.validateConflictingAttributes(k, schema, c)
	if err != nil {
		return nil, []error{err}
	}

	return m.validateType(k, raw, schema, c)
}

func (m schemaMap) validateConflictingAttributes(
	k string,
	schema *Schema,
	c *terraform.ResourceConfig) error {

	if len(schema.ConflictsWith) == 0 {
		return nil
	}

	for _, conflicting_key := range schema.ConflictsWith {
		if value, ok := c.Get(conflicting_key); ok {
			return fmt.Errorf(
				"%q: conflicts with %s (%#v)", k, conflicting_key, value)
		}
	}

	return nil
}

func (m schemaMap) validateList(
	k string,
	raw interface{},
	schema *Schema,
	c *terraform.ResourceConfig) ([]string, []error) {
	// We use reflection to verify the slice because you can't
	// case to []interface{} unless the slice is exactly that type.
	rawV := reflect.ValueOf(raw)
	if rawV.Kind() != reflect.Slice {
		return nil, []error{fmt.Errorf(
			"%s: should be a list", k)}
	}

	// Now build the []interface{}
	raws := make([]interface{}, rawV.Len())
	for i, _ := range raws {
		raws[i] = rawV.Index(i).Interface()
	}

	var ws []string
	var es []error
	for i, raw := range raws {
		key := fmt.Sprintf("%s.%d", k, i)

		var ws2 []string
		var es2 []error
		switch t := schema.Elem.(type) {
		case *Resource:
			// This is a sub-resource
			ws2, es2 = m.validateObject(key, t.Schema, c)
		case *Schema:
			ws2, es2 = m.validateType(key, raw, t, c)
		}

		if len(ws2) > 0 {
			ws = append(ws, ws2...)
		}
		if len(es2) > 0 {
			es = append(es, es2...)
		}
	}

	return ws, es
}

func (m schemaMap) validateMap(
	k string,
	raw interface{},
	schema *Schema,
	c *terraform.ResourceConfig) ([]string, []error) {
	// We use reflection to verify the slice because you can't
	// case to []interface{} unless the slice is exactly that type.
	rawV := reflect.ValueOf(raw)
	switch rawV.Kind() {
	case reflect.Map:
	case reflect.Slice:
	default:
		return nil, []error{fmt.Errorf(
			"%s: should be a map", k)}
	}

	// If it is not a slice, it is valid
	if rawV.Kind() != reflect.Slice {
		return nil, nil
	}

	// It is a slice, verify that all the elements are maps
	raws := make([]interface{}, rawV.Len())
	for i, _ := range raws {
		raws[i] = rawV.Index(i).Interface()
	}

	for _, raw := range raws {
		v := reflect.ValueOf(raw)
		if v.Kind() != reflect.Map {
			return nil, []error{fmt.Errorf(
				"%s: should be a map", k)}
		}
	}

	return nil, nil
}

func (m schemaMap) validateObject(
	k string,
	schema map[string]*Schema,
	c *terraform.ResourceConfig) ([]string, []error) {
	var ws []string
	var es []error
	for subK, s := range schema {
		key := subK
		if k != "" {
			key = fmt.Sprintf("%s.%s", k, subK)
		}

		ws2, es2 := m.validate(key, s, c)
		if len(ws2) > 0 {
			ws = append(ws, ws2...)
		}
		if len(es2) > 0 {
			es = append(es, es2...)
		}
	}

	// Detect any extra/unknown keys and report those as errors.
	raw, _ := c.GetRaw(k)
	if m, ok := raw.(map[string]interface{}); ok {
		for subk, _ := range m {
			if _, ok := schema[subk]; !ok {
				es = append(es, fmt.Errorf(
					"%s: invalid or unknown key: %s", k, subk))
			}
		}
	}

	return ws, es
}

func (m schemaMap) validatePrimitive(
	k string,
	raw interface{},
	schema *Schema,
	c *terraform.ResourceConfig) ([]string, []error) {
	if c.IsComputed(k) {
		// If the key is being computed, then it is not an error
		return nil, nil
	}

	switch schema.Type {
	case TypeBool:
		// Verify that we can parse this as the correct type
		var n bool
		if err := mapstructure.WeakDecode(raw, &n); err != nil {
			return nil, []error{err}
		}
	case TypeInt:
		// Verify that we can parse this as an int
		var n int
		if err := mapstructure.WeakDecode(raw, &n); err != nil {
			return nil, []error{err}
		}
	case TypeFloat:
		// Verify that we can parse this as an int
		var n float64
		if err := mapstructure.WeakDecode(raw, &n); err != nil {
			return nil, []error{err}
		}
	case TypeString:
		// Verify that we can parse this as a string
		var n string
		if err := mapstructure.WeakDecode(raw, &n); err != nil {
			return nil, []error{err}
		}
	default:
		panic(fmt.Sprintf("Unknown validation type: %#v", schema.Type))
	}

	return nil, nil
}

func (m schemaMap) validateType(
	k string,
	raw interface{},
	schema *Schema,
	c *terraform.ResourceConfig) ([]string, []error) {
	var ws []string
	var es []error
	switch schema.Type {
	case TypeSet, TypeList:
		ws, es = m.validateList(k, raw, schema, c)
	case TypeMap:
		ws, es = m.validateMap(k, raw, schema, c)
	default:
		ws, es = m.validatePrimitive(k, raw, schema, c)
	}

	if schema.Deprecated != "" {
		ws = append(ws, fmt.Sprintf(
			"%q: [DEPRECATED] %s", k, schema.Deprecated))
	}

	if schema.Removed != "" {
		es = append(es, fmt.Errorf(
			"%q: [REMOVED] %s", k, schema.Removed))
	}

	return ws, es
}

// Zero returns the zero value for a type.
func (t ValueType) Zero() interface{} {
	switch t {
	case TypeInvalid:
		return nil
	case TypeBool:
		return false
	case TypeInt:
		return 0
	case TypeFloat:
		return 0.0
	case TypeString:
		return ""
	case TypeList:
		return []interface{}{}
	case TypeMap:
		return map[string]interface{}{}
	case TypeSet:
		return new(Set)
	case typeObject:
		return map[string]interface{}{}
	default:
		panic(fmt.Sprintf("unknown type %s", t))
	}
}
