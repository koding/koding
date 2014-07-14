package main

import (
	"encoding/json"
	"fmt"

	"github.com/koding/kite"
)

func main() {
	k := kite.New("bongo", "0.0.1")
	k.HandleFunc("bongo", Bongo).DisableAuthentication()
	k.Config.Port = 3636
	k.Run()
}

func Bongo(r *kite.Request) (interface{}, error) {
	a := r.Args.One().MustMap()

	fmt.Printf(`
"Call received:,
Type          : %s",
Method        : %s",
Id            : %s",
Arguments     : %s",
`,
		a["type"],
		a["method"],
		a["id"],
		a["arguments"],
	)

	res, err := json.Marshal(a)
	if err != nil {
		return nil, err
	}

	// return what you get as string
	return string(res), nil
}
