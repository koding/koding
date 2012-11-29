package virt

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strings"
)

type User struct {
	Name        string
	Gid         int
	Description string
	Home        string
	Shell       string
}

type Group struct {
	Name  string
	Users map[string]bool
}

func ReadPasswd(fileName string) (map[int]*User, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return make(map[int]*User, 0), err
	}
	defer f.Close()
	r := bufio.NewReader(f)

	users := make(map[int]*User, 0)
	for !atEndOfFile(r) {
		user := User{}
		user.Name = readUntil(r, ':')
		readUntil(r, ':') // skip
		uid := atoi(readUntil(r, ':'))
		user.Gid = atoi(readUntil(r, ':'))
		user.Description = readUntil(r, ':')
		user.Home = readUntil(r, ':')
		user.Shell = readUntil(r, '\n')
		users[uid] = &user
	}
	return users, nil
}

func WritePasswd(users map[int]*User, fileName string) error {
	f, err := os.Create(fileName)
	if err != nil {
		return err
	}
	defer f.Close()

	uids := make([]int, 0, len(users))
	for uid, _ := range users {
		uids = append(uids, uid)
	}
	sort.Ints(uids)

	for _, uid := range uids {
		user := users[uid]
		_, err := fmt.Fprintf(f, "%s:x:%d:%d:%s:%s:%s\n", user.Name, uid, user.Gid, user.Description, user.Home, user.Shell)
		if err != nil {
			return err
		}
	}

	return nil
}

func ReadGroup(fileName string) (map[int]*Group, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return make(map[int]*Group, 0), err
	}
	defer f.Close()
	r := bufio.NewReader(f)

	groups := make(map[int]*Group, 0)
	for !atEndOfFile(r) {
		group := Group{Users: make(map[string]bool)}
		group.Name = readUntil(r, ':')
		readUntil(r, ':') // skip
		gid := atoi(readUntil(r, ':'))
		for _, user := range strings.Split(readUntil(r, '\n'), ",") {
			group.Users[user] = true
		}
		groups[gid] = &group
	}
	return groups, nil
}

func WriteGroup(groups map[int]*Group, fileName string) error {
	f, err := os.Create(fileName)
	if err != nil {
		return err
	}
	defer f.Close()

	gids := make([]int, 0, len(groups))
	for gid, _ := range groups {
		gids = append(gids, gid)
	}
	sort.Ints(gids)

	for _, gid := range gids {
		group := groups[gid]
		users := ""
		for user := range group.Users {
			if len(users) != 0 {
				users += ","
			}
			users += user
		}
		_, err := fmt.Fprintf(f, "%s:x:%d:%s\n", group.Name, gid, users)
		if err != nil {
			return err
		}
	}

	return nil
}
