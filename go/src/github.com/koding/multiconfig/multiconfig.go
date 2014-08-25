package multiconfig

import (
	"errors"
	"fmt"
	"reflect"
	"strconv"
	"strings"

	"github.com/fatih/structs"
)

// Loader loads the configuration from a source
type Loader interface {
	// Load loads the source into the config defined by struct s
	Load(s interface{}) error
}

// DefaultLoader implements the Loader interface. It initializes the given
// pointer of struct s with configuration from the default sources. The order
// of load is LoadFile, LoadEnv and lastly LoadFlag.  An error in any step
// stops the loading process. Each step overrides the previous step's config
// (i.e: defining a flag will override previous environment or file config). To
// customize the order use the individual load functions.
type DefaultLoader struct {
	Loader
}

// NewWithPath returns a new instance of Loader to read from the given
// configuration file.
func NewWithPath(path string) *DefaultLoader {
	loaders := []Loader{}

	// Choose what while is passed
	if strings.HasSuffix(path, "toml") {
		loaders = append(loaders, &TOMLLoader{Path: path})
	}

	if strings.HasSuffix(path, "json") {
		loaders = append(loaders, &JSONLoader{Path: path})
	}

	loaders = append(loaders, &EnvironmentLoader{}, &FlagLoader{})
	loader := MultiLoader(loaders...)

	d := &DefaultLoader{}
	d.Loader = loader
	return d
}

// New returns a new instance of DefaultLoader without any file loaders.
func New() *DefaultLoader {
	loader := MultiLoader(
		&EnvironmentLoader{},
		&FlagLoader{},
	)

	d := &DefaultLoader{}
	d.Loader = loader
	return d
}

// MustLoad is like Load but panics if the config cannot be parsed.
func (d *DefaultLoader) MustLoad(conf interface{}) {
	if err := d.Load(conf); err != nil {
		panic(err)
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
