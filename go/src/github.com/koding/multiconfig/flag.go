package multiconfig

import (
	"flag"
	"fmt"
	"os"
	"reflect"
	"strings"

	"github.com/fatih/camelcase"
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

	// Flatten doesn't add prefixes for nested structs. So previously if we had
	// a nested struct `type T struct{Name struct{ ...}}`, this would generate
	// --name-foo, --name-bar, etc. When Flatten is enabled, the flags will be
	// flattend to the form: --foo, --bar, etc.. Panics if the nested structs
	// has a duplicate field name in the root level of the struct (outer
	// struct). Use this option only if you know what you do.
	Flatten bool

	// CamelCase adds a seperator for field names in camelcase form. A
	// fieldname of "AccessKey" would generate a flag name "--accesskey". If
	// CamelCase is enabled, the flag name will be generated in the form of
	// "--access-key"
	CamelCase bool

	// EnvPrefix is just a placeholder to print the correct usages when an
	// EnvLoader is used
	EnvPrefix string

	// Args defines a custom argument list. If nil, os.Args[1:] is used.
	Args []string
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
		e := &EnvironmentLoader{
			Prefix:    f.EnvPrefix,
			CamelCase: f.CamelCase,
		}
		e.PrintEnvs(s)
		fmt.Println("")
	}

	args := os.Args[1:]
	if f.Args != nil {
		args = f.Args
	}

	return flagSet.Parse(args)
}

// processField generates a flag based on the given field and fieldName. If a
// nested struct is detected, a flag for each field of that nested struct is
// generated too.
func (f *FlagLoader) processField(flagSet *flag.FlagSet, fieldName string, field *structs.Field) error {
	if f.CamelCase {
		fieldName = strings.Join(camelcase.Split(fieldName), "-")
	}

	switch field.Kind() {
	case reflect.Struct:
		for _, ff := range field.Fields() {
			flagName := field.Name() + "-" + ff.Name()

			if f.Flatten {
				// first check if it's set or not, because if we have duplicate
				// we don't want to break the flag. Panic by giving a readable
				// output
				flagSet.VisitAll(func(fl *flag.Flag) {
					if strings.ToLower(ff.Name()) == fl.Name {
						// already defined
						panic(fmt.Sprintf("flag '%s' is already defined in outer struct", fl.Name))
					}
				})

				flagName = ff.Name()
			}

			if err := f.processField(flagSet, flagName, ff); err != nil {
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
