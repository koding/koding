package multiconfig

import (
	"fmt"
	"os"
	"strings"

	"github.com/fatih/structs"
)

// EnvironmentLoader satisifies the loader interface. It loads the
// configuration from the environment variables in the form of
// STRUCTNAME_FIELDNAME.
type EnvironmentLoader struct{}

func (e *EnvironmentLoader) Load(s interface{}) error {
	strct := structs.New(s)
	strctName := strct.Name()

	for _, field := range strct.Fields() {
		envName := strings.ToUpper(strctName) + "_" + strings.ToUpper(field.Name())

		v := os.Getenv(envName)
		if v == "" {
			continue
		}

		if err := fieldSet(field, v); err != nil {
			return err
		}
	}

	return nil
}

// PrintEnvs prints the generated environment variables to the std out.
func (e *EnvironmentLoader) PrintEnvs(s interface{}) {
	strct := structs.New(s)
	strctName := strct.Name()

	for _, field := range strct.Fields() {
		envName := strings.ToUpper(strctName) + "_" + strings.ToUpper(field.Name())
		fmt.Println("  ", envName)
	}
}
