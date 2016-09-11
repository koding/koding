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

	// CamelCase adds a separator for field names in camelcase form. A
	// fieldname of "AccessKey" would generate a flag name "--accesskey". If
	// CamelCase is enabled, the flag name will be generated in the form of
	// "--access-key"
	CamelCase bool

	// EnvPrefix is just a placeholder to print the correct usages when an
	// EnvLoader is used
	EnvPrefix string

	// Args defines a custom argument list. If nil, os.Args[1:] is used.
	Args []string

	// FlagUsageFunc an optional function that is called to set a flag.Usage value
	// The input is the raw flag name, and the output should be a string
	// that will used in passed into the flag for Usage.
	FlagUsageFunc func(name string) string

	// only exists for testing.  This is the raw flagset that is to parse
	flagSet *flag.FlagSet
}

// Load loads the source into the config defined by struct s
func (f *FlagLoader) Load(s interface{}) error {
	strct := structs.New(s)
	structName := strct.Name()

	flagSet := flag.NewFlagSet(structName, flag.ExitOnError)
	f.flagSet = flagSet

	for _, field := range strct.Fields() {
		f.processField(field.Name(), field)
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
func (f *FlagLoader) processField(fieldName string, field *structs.Field) error {
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
				f.flagSet.VisitAll(func(fl *flag.Flag) {
					if strings.ToLower(ff.Name()) == fl.Name {
						// already defined
						panic(fmt.Sprintf("flag '%s' is already defined in outer struct", fl.Name))
					}
				})

				flagName = ff.Name()
			}

			if err := f.processField(flagName, ff); err != nil {
				return err
			}
		}
	default:
		// Add custom prefix to the flag if it's set
		if f.Prefix != "" {
			fieldName = f.Prefix + "-" + fieldName
		}

		// we only can get the value from expored fields, unexported fields panics
		if field.IsExported() {
			// use built-in or custom flag usage message
			flagUsageFunc := flagUsageDefault
			if f.FlagUsageFunc != nil {
				flagUsageFunc = f.FlagUsageFunc
			}
			f.flagSet.Var(newFieldValue(field), flagName(fieldName), flagUsageFunc(fieldName))
		}
	}

	return nil
}

// fieldValue satisfies the flag.Value and flag.Getter interfaces
type fieldValue struct {
	field *structs.Field
}

func newFieldValue(f *structs.Field) *fieldValue {
	return &fieldValue{
		field: f,
	}
}

func (f *fieldValue) Set(val string) error {
	return fieldSet(f.field, val)
}

func (f *fieldValue) String() string {
	if f.IsZero() {
		return ""
	}

	return fmt.Sprintf("%v", f.field.Value())
}

func (f *fieldValue) Get() interface{} {
	if f.IsZero() {
		return nil
	}

	return f.field.Value()
}

func (f *fieldValue) IsZero() bool {
	return f.field == nil
}

// This is an unexported interface, be careful about it.
// https://code.google.com/p/go/source/browse/src/pkg/flag/flag.go?name=release#101
func (f *fieldValue) IsBoolFlag() bool {
	return f.field.Kind() == reflect.Bool
}

// flagUsageDefault is the default "FlagUsageFunc" use in filling out
// the usage of a flag.
func flagUsageDefault(name string) string { return fmt.Sprintf("Change value of %s.", name) }

func flagName(name string) string { return strings.ToLower(name) }
