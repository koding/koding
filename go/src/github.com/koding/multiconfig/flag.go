package multiconfig

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/fatih/structs"
)

// FlagLoader satisfies the loader interface. It creates on the fly flags based
// on the field names and parses them to load into the given pointer of struct
// s.
type FlagLoader struct{}

func (f *FlagLoader) Load(s interface{}) error {
	strct := structs.New(s)
	structName := strct.Name()

	flagSet := flag.NewFlagSet(structName, flag.ExitOnError)
	// f.SetOutput(ioutil.Discard)

	for _, field := range strct.Fields() {
		name := field.Name()

		flagSet.Var(newFieldValue(field), flagName(name), flagUsage(name))
	}

	flagSet.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		flagSet.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nGenerated environment variables:\n")
		e := &EnvironmentLoader{}
		e.PrintEnvs(s)
		fmt.Println("")
	}

	return flagSet.Parse(os.Args[1:])
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

func flagUsage(name string) string { return fmt.Sprintf("Change value of %s.", name) }

func flagName(name string) string { return strings.ToLower(name) }
