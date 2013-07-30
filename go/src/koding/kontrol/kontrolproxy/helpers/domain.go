package main

import (
	"fmt"
	"koding/kontrol/kontrolproxy/resolver"
	"koding/tools/config"
)

func main() {
	target, err := resolver.GetTarget(config.Host)
	if err != nil {
		fmt.Println("error:", err)
		return
	}

	fmt.Println(target.Mode, target.Url.String())
}
