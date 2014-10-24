package multiconfig

import (
	"flag"
	"fmt"
	"os"
	"reflect"
	"strings"

	"github.com/fatih/structs"
)

// FlagLoader satisfies the loader interface. It creates on the fly flags based
// on the field names and parses them to load into the given pointer of struct
// s.
type FlagLoader struct {
	// Prefix prepends the prefix to each flag name i.e:
	// --foo is converted to --prefix-foo.
	// --foo-bar is converted to --prefix-foo-bar.
	Prefix string

	// EnvPrefix is just a placeholder to print the correct usages when an
	// EnvLoader is used
	EnvPrefix string

	// args defines a custom argument list that overides os.Args[]
	args []string
}

// Load loads the source into the config defined by struct s
func (f *FlagLoader) Load(s interface{}) error {
	strct := structs.New(s)
	structName := strct.Name()

	flagSet := flag.NewFlagSet(structName, flag.ExitOnError)

	for _, field := range strct.Fields() {
		f.processField(flagSet, field.Name(), field)
	}

	flagSet.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		flagSet.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nGenerated environment variables:\n")
		e := &EnvironmentLoader{f.EnvPrefix}
		e.PrintEnvs(s)
		fmt.Println("")
	}

	args := os.Args[1:]
	if f.args != nil {
		args = f.args
	}

	return flagSet.Parse(args)
}

// processField generates a flag based on the given field and fieldName. If a
// nested struct is detected, a flag for each field of that nested struct is
// generated too.
func (f *FlagLoader) processField(flagSet *flag.FlagSet, fieldName string, field *structs.Field) error {
	switch field.Kind() {
	case reflect.Struct:
		for _, ff := range field.Fields() {
			if err := f.processField(flagSet, field.Name()+"-"+ff.Name(), ff); err != nil {
				return err
			}
		}
	default:
		// Add custom prefix to the flag if it's set
		if f.Prefix != "" {
			fieldName = f.Prefix + "-" + fieldName
		}

		flagSet.Var(newFieldValue(field), flagName(fieldName), flagUsage(fieldName))
	}

	return nil
}

// fieldValue satisfies the flag.Value and flag.Getter interfaces
type fieldValue structs.Field

func newFieldValue(f *structs.Field) *fieldValue {
	fl := fieldValue(*f)
	return &fl
}

func (f *fieldValue) Set(val string) error {
	field := (*structs.Field)(f)
	return fieldSet(field, val)
}

func (f *fieldValue) String() string {
	fl := (*structs.Field)(f)
	return fmt.Sprintf("%v", fl.Value())
}

func (f *fieldValue) Get() interface{} {
	fl := (*structs.Field)(f)
	return fl.Value()
}

// This is an unexported interface, be careful about it.
// https://code.google.com/p/go/source/browse/src/pkg/flag/flag.go?name=release#101
func (f *fieldValue) IsBoolFlag() bool {
	fl := (*structs.Field)(f)
	if fl.Kind() == reflect.Bool {
		return true
	}
	return false
}

func flagUsage(name string) string { return fmt.Sprintf("Change value of %s.", name) }

func flagName(name string) string { return strings.ToLower(name) }
