package main

import (
	"fmt"
	"koding/tools/db"
	"koding/tools/utils"
	"os/user"
)

func main() {
	utils.Startup("ldap2mongodb", false)

	iter := db.Users.Find(nil).Iter()
	var mongoUser db.User
	for iter.Next(&mongoUser) {
		_, err := user.Lookup(mongoUser.Name)
		if err != nil {
			fmt.Println(mongoUser.Name, err.Error())
		}
	}
	if iter.Err() != nil {
		panic(iter.Err())
	}
}
