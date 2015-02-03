package main

import (
	"fmt"
	"time"
)

type Inactive struct {
	Assigned               bool
	AssignedAt, ModifiedAt time.Time
}

var Warnings = []*Warning{
	FirstEmail, SecondEmail, ThirdEmail, FourthDeleteVM,
}

func main() {
	for _, warning := range Warnings {
		result := warning.Run()
		fmt.Println(result)
	}
}

func handleError(err error) {
	fmt.Println(err)
}
