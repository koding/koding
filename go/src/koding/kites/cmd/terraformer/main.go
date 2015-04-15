package main

import (
	"fmt"

	"github.com/hashicorp/terraform/terraform"
)

func main() {
	var cts terraform.ContextOpts
	fmt.Println("cts-->", cts)
	// config := terraform.BuiltinConfig
	// if err := config.Discover(); err != nil {
	// 	Ui.Error(fmt.Sprintf("Error discovering plugins: %s", err))
	// 	return 1
	// }
}
