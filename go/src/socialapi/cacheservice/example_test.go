package cacheservice

import (
	"fmt"
	"socialapi/models"
)

func Example() {
	a := NewChannelContainerService()
	cc := models.NewChannelContainer()
	fmt.Println(a.Set(1, cc))
	fmt.Println(a.Get(1))
}
