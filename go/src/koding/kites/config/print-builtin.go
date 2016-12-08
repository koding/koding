// +build ignore

package main

import (
	"encoding/json"
	"os"

	"koding/kites/config"
)

func main() {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "\t")
	enc.Encode(config.Builtin)
}
