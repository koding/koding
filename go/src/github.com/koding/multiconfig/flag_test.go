package multiconfig

import (
	"strings"
	"testing"

	"github.com/fatih/structs"
)

func TestFlag(t *testing.T) {
	m := &FlagLoader{}
	s := &Server{}
	structName := structs.Name(s)

	// get flags
	args := getFlags(t, structName, "")

	m.args = args[1:]

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

func TestFlagWithPrefix(t *testing.T) {
	const prefix = "Prefix"

	m := FlagLoader{Prefix: prefix}
	s := &Server{}
	structName := structs.Name(s)

	// get flags
	args := getFlags(t, structName, prefix)

	m.args = args[1:]

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

// getFlags returns a slice of arguments that can be passed to flag.Parse()
func getFlags(t *testing.T, structName, prefix string) []string {
	if structName == "" {
		t.Fatal("struct name can not be empty")
	}

	flags := map[string]string{
		"-name":                       "koding",
		"-port":                       "6060",
		"-enabled":                    "",
		"-users":                      "ankara,istanbul",
		"-postgres-enabled":           "",
		"-postgres-port":              "5432",
		"-postgres-hosts":             "192.168.2.1,192.168.2.2,192.168.2.3",
		"-postgres-dbname":            "configdb",
		"-postgres-availabilityratio": "8.23",
	}

	prefix = strings.ToLower(prefix)

	args := []string{"multiconfig-test"}
	for key, val := range flags {
		flag := key
		if prefix != "" {
			flag = "-" + prefix + key
		}

		if val == "" {
			args = append(args, flag)
		} else {
			args = append(args, flag, val)
		}
	}

	return args
}
