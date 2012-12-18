package virt

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strings"
)

type SysUser struct {
	Name        string
	Gid         int
	Description string
	Home        string
	Shell       string
}

type SysGroup struct {
	Name  string
	Users map[string]bool
}

func (vm *VM) MergePasswdFile() {
	passwdFile := vm.UpperdirFile("/etc/passwd")
	users, _ := ReadPasswd(passwdFile) // error ignored

	lowerUsers, err := ReadPasswd(LowerdirFile("/etc/passwd"))
	if err != nil {
		panic(err)
	}
	for uid, user := range lowerUsers {
		users[uid] = user
	}

	err = WritePasswd(users, passwdFile)
	if err != nil {
		panic(err)
	}
	os.Chown(passwdFile, VMROOT_ID, VMROOT_ID)
}

func (vm *VM) MergeGroupFile() {
	groupFile := vm.UpperdirFile("/etc/group")
	groups, _ := ReadGroup(groupFile) // error ignored

	lowerGroups, err := ReadGroup(LowerdirFile("/etc/group"))
	if err != nil {
		panic(err)
	}
	for gid, group := range lowerGroups {
		if groups[gid] != nil {
			for user := range groups[gid].Users {
				group.Users[user] = true
			}
		}
		groups[gid] = group
	}

	if err := WriteGroup(groups, groupFile); err != nil {
		panic(err)
	}
	os.Chown(groupFile, VMROOT_ID, VMROOT_ID)
}

func ReadPasswd(fileName string) (map[int]*SysUser, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return make(map[int]*SysUser, 0), err
	}
	defer f.Close()
	r := bufio.NewReader(f)

	users := make(map[int]*SysUser, 0)
	for !atEndOfFile(r) {
		user := SysUser{}
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

func WritePasswd(users map[int]*SysUser, fileName string) error {
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
		if _, err := fmt.Fprintf(f, "%s:x:%d:%d:%s:%s:%s\n", user.Name, uid, user.Gid, user.Description, user.Home, user.Shell); err != nil {
			return err
		}
	}

	return nil
}

func ReadGroup(fileName string) (map[int]*SysGroup, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return make(map[int]*SysGroup, 0), err
	}
	defer f.Close()
	r := bufio.NewReader(f)

	groups := make(map[int]*SysGroup, 0)
	for !atEndOfFile(r) {
		group := SysGroup{Users: make(map[string]bool)}
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

func WriteGroup(groups map[int]*SysGroup, fileName string) error {
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
		if _, err := fmt.Fprintf(f, "%s:x:%d:%s\n", group.Name, gid, users); err != nil {
			return err
		}
	}

	return nil
}
