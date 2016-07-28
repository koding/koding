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

	m.Args = args[1:]

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

	m.Args = args[1:]

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

func TestFlattenFlags(t *testing.T) {
	m := FlagLoader{
		Flatten: true,
	}
	s := &FlattenedServer{}
	structName := structs.Name(s)

	// get flags
	args := getFlags(t, structName, "")

	m.Args = args[1:]

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testFlattenedStruct(t, s, getDefaultServer())
}

func TestCamelcaseFlags(t *testing.T) {
	m := FlagLoader{
		CamelCase: true,
	}
	s := &CamelCaseServer{}
	structName := structs.Name(s)

	// get flags
	args := getFlags(t, structName, "")

	m.Args = args[1:]

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testCamelcaseStruct(t, s, getDefaultCamelCaseServer())
}

func TestFlattenAndCamelCaseFlags(t *testing.T) {
	m := FlagLoader{
		Flatten:   true,
		CamelCase: true,
	}
	s := &FlattenedServer{}

	// get flags
	args := getFlags(t, "FlattenedCamelCaseServer", "")

	m.Args = args[1:]

	if err := m.Load(s); err != nil {
		t.Error(err)
	}
}

func TestCustomUsageFunc(t *testing.T) {
	const usageMsg = "foobar help"
	strt := struct {
		Foobar string
	}{}
	m := FlagLoader{
		FlagUsageFunc: (func(s string) string { return usageMsg }),
	}
	err := m.Load(&strt)

	if err != nil {
		t.Fatalf("Unable to load struct: %s", err)
	}
	f := m.flagSet.Lookup("foobar")
	if f == nil {
		t.Fatalf("Flag foobar is not set")
	}
	if f.Usage != usageMsg {
		t.Fatalf("usage message was %q, expected %q", f.Usage, usageMsg)
	}
}

// getFlags returns a slice of arguments that can be passed to flag.Parse()
func getFlags(t *testing.T, structName, prefix string) []string {
	if structName == "" {
		t.Fatal("struct name can not be empty")
	}

	var flags map[string]string
	switch structName {
	case "Server":
		flags = map[string]string{
			"-name":                       "koding",
			"-port":                       "6060",
			"-enabled":                    "",
			"-users":                      "ankara,istanbul",
			"-interval":                   "10s",
			"-id":                         "1234567890",
			"-labels":                     "123,456",
			"-postgres-enabled":           "",
			"-postgres-port":              "5432",
			"-postgres-hosts":             "192.168.2.1,192.168.2.2,192.168.2.3",
			"-postgres-dbname":            "configdb",
			"-postgres-availabilityratio": "8.23",
		}
	case "FlattenedServer":
		flags = map[string]string{
			"--enabled":           "",
			"--port":              "5432",
			"--hosts":             "192.168.2.1,192.168.2.2,192.168.2.3",
			"--dbname":            "configdb",
			"--availabilityratio": "8.23",
		}
	case "FlattenedCamelCaseServer":
		flags = map[string]string{
			"--enabled":            "",
			"--port":               "5432",
			"--hosts":              "192.168.2.1,192.168.2.2,192.168.2.3",
			"--db-name":            "configdb",
			"--availability-ratio": "8.23",
		}
	case "CamelCaseServer":
		flags = map[string]string{
			"--access-key":         "123456",
			"--normal":             "normal",
			"--db-name":            "configdb",
			"--availability-ratio": "8.23",
		}
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
