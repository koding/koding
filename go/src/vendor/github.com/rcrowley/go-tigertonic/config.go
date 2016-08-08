package tigertonic

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

// ConfigExt maps all known configuration file extensions to their
// read-and-unmarshal functions.

type configParser func(string, interface{}) error

var ConfigExt = make(map[string]configParser)

func RegisterConfigExt(ext string, f configParser) {
	ConfigExt[ext] = f
}

func init() {
	RegisterConfigExt(".json", ConfigureJSON)
}

// Configure delegates reading and unmarshaling of the given configuration
// file to the appropriate function from ConfigExt.  For convenient use with
// the flags package, an empty pathname is not considered an error.
func Configure(pathname string, i interface{}) error {
	if "" == pathname {
		return nil
	}
	ext := filepath.Ext(pathname)
	if "" == ext {
		return errors.New("configuration file must have an extension")
	}
	f, ok := ConfigExt[ext]
	if !ok {
		return fmt.Errorf(
			"configuration file extension \"%s\" not recognized",
			ext,
		)
	}
	return f(pathname, i)
}

// ConfigureJSON reads the given configuration file and unmarshals the JSON
// found into the given configuration structure.  For convenient use with
// the flags package, an empty pathname is not considered an error.
func ConfigureJSON(pathname string, i interface{}) error {
	if "" == pathname {
		return nil
	}
	f, err := os.Open(pathname)
	if nil != err {
		return err
	}
	defer f.Close()
	return json.NewDecoder(f).Decode(i)
}
