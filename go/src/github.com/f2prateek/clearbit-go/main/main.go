package main

import (
	"fmt"

	"github.com/f2prateek/clearbit-go"
)

func main() {
	c := clearbit.New("9d961e7ac862a6bc430f783da5cf9422")

	combined, err := c.Enrichment().Combined("mehmet@koding.com")
	if err != nil {
		fmt.Println("error:", err)
		return
	}

	fmt.Println(*combined.Person.Name.FullName)
	fmt.Println(*combined.Company.Name)
	fmt.Println(*combined.Company.Metrics.Employees)

	// Output:
	// Prateek Srivastava
	// Segment
}
