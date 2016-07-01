package clearbit_test

import (
	"fmt"

	"github.com/f2prateek/clearbit-go"
)

func ExampleCombined() {
	c := clearbit.New("93281a7c96132e8503acc84467be8c62")

	combined, err := c.Enrichment().Combined("prateek@segment.com")
	if err != nil {
		fmt.Println("error:", err)
		return
	}

	fmt.Println(*combined.Person.Name.FullName)
	fmt.Println(*combined.Company.Name)

	// Output:
	// Prateek Srivastava
	// Segment
}

func ExampleCombinedWithoutCompany() {
	c := clearbit.New("93281a7c96132e8503acc84467be8c62")

	combined, err := c.Enrichment().Combined("f2prateek@gmail.com")
	if err != nil {
		fmt.Println("error:", err)
		return
	}

	fmt.Println(*combined.Person.Name.FullName)

	// Output:
	// Prateek Srivastava
}
