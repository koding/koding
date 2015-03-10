package multiconfig

import (
	"errors"
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"

	"github.com/fatih/structs"
)

// Loader loads the configuration from a source. The implementer of Loader is
// responsible of setting the default values of the struct.
type Loader interface {
	// Load loads the source into the config defined by struct s
	Load(s interface{}) error
}

// DefaultLoader implements the Loader interface. It initializes the given
// pointer of struct s with configuration from the default sources. The order
// of load is TagLoader, FileLoader, EnvLoader and lastly FlagLoader. An error
// in any step stops the loading process. Each step overrides the previous
// step's config (i.e: defining a flag will override previous environment or
// file config). To customize the order use the individual load functions.
type DefaultLoader struct {
	Loader
	Validator
}

// NewWithPath returns a new instance of Loader to read from the given
// configuration file.
func NewWithPath(path string) *DefaultLoader {
	loaders := []Loader{}

	// Read default values defined via tag fields "default"
	loaders = append(loaders, &TagLoader{})

	// Choose what while is passed
	if strings.HasSuffix(path, "toml") {
		loaders = append(loaders, &TOMLLoader{Path: path})
	}

	if strings.HasSuffix(path, "json") {
		loaders = append(loaders, &JSONLoader{Path: path})
	}

	e := &EnvironmentLoader{}
	f := &FlagLoader{}

	loaders = append(loaders, e, f)
	loader := MultiLoader(loaders...)

	d := &DefaultLoader{}
	d.Loader = loader
	d.Validator = MultiValidator(&RequiredValidator{})
	return d
}

// New returns a new instance of DefaultLoader without any file loaders.
func New() *DefaultLoader {
	loader := MultiLoader(
		&TagLoader{},
		&EnvironmentLoader{},
		&FlagLoader{},
	)

	d := &DefaultLoader{}
	d.Loader = loader
	d.Validator = MultiValidator(&RequiredValidator{})
	return d
}

// MustLoadWithPath loads with the DefaultLoader settings and from the given
// Path. It exits if the config cannot be parsed.
func MustLoadWithPath(path string, conf interface{}) {
	d := NewWithPath(path)
	d.MustLoad(conf)
}

// MustLoad loads with the DefaultLoader settings. It exits if the config
// cannot be parsed.
func MustLoad(conf interface{}) {
	d := New()
	d.MustLoad(conf)
}

// MustLoad is like Load but panics if the config cannot be parsed.
func (d *DefaultLoader) MustLoad(conf interface{}) {
	if err := d.Load(conf); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}

	// we at koding, believe having sane defaults in our system, this is the
	// reason why we have default validators in DefaultLoader. But do not cause
	// nil pointer panics if one uses DefaultLoader directly.
	if d.Validator != nil {
		d.MustValidate(conf)
	}
}

// MustValidate validates the struct. It exits with status 1 if it can't
// validate.
func (d *DefaultLoader) MustValidate(conf interface{}) {
	if err := d.Validate(conf); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
}

// fieldSet sets field value from the given string value. It converts the
// string value in a sane way and is usefulf or environment variables or flags
// which are by nature in string types.
func fieldSet(field *structs.Field, v string) error {
	// TODO: add support for other types
	switch field.Kind() {
	case reflect.Bool:
		val, err := strconv.ParseBool(v)
		if err != nil {
			return err
		}

		if err := field.Set(val); err != nil {
			return err
		}
	case reflect.Int:
		i, err := strconv.Atoi(v)
		if err != nil {
			return err
		}

		if err := field.Set(i); err != nil {
			return err
		}
	case reflect.String:
		field.Set(v)
	case reflect.Slice:
		// TODO add other typed slice support
		if _, ok := field.Value().([]string); !ok {
			return errors.New("can't set on non string slices")
		}

		if err := field.Set(strings.Split(v, ",")); err != nil {
			return err
		}
	case reflect.Float64:
		f, err := strconv.ParseFloat(v, 64)
		if err != nil {
			return err
		}

		if err := field.Set(f); err != nil {
			return err
		}
	default:
		return fmt.Errorf("multiconfig: not supported type: %s", field.Kind())
	}

	return nil
}
