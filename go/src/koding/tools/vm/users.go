package vm

import (
	"bufio"
	"fmt"
	"os"
)

type User struct {
	Name        string
	Uid         int
	Gid         int
	Description string
	Home        string
	Shell       string
}

func ReadPasswd(fileName string) []*User {
	f, err := os.Open(fileName)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	r := bufio.NewReader(f)

	users := make([]*User, 0)
	for !atEndOfFile(r) {
		user := &User{}
		users = append(users, user)
		user.Name = readUntil(r, ':')
		readUntil(r, ':') // skip
		user.Uid = atoi(readUntil(r, ':'))
		user.Gid = atoi(readUntil(r, ':'))
		user.Description = readUntil(r, ':')
		user.Home = readUntil(r, ':')
		user.Shell = readUntil(r, '\n')
	}
	return users
}

func WritePasswd(users []*User, fileName string) {
	f, err := os.Create(fileName)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	for _, user := range users {
		_, err := fmt.Fprintf(f, "%s:x:%d:%d:%s:%s:%s\n", user.Name, user.Uid, user.Gid, user.Description, user.Home, user.Shell)
		if err != nil {
			panic(err)
		}
	}
}
