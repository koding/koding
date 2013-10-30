package container

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
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

func (c *Container) MergePasswdFile() {
	passwdFile := c.Dir + "/overlay/etc/passwd"
	users, err := ReadPasswd(passwdFile) // error ignored
	if err != nil {
		if os.IsNotExist(err) {
			return // no file in upper, no need to merge
		}
		err := os.Rename(passwdFile, passwdFile+"_corrupt_"+time.Now().Format(time.RFC3339))
		if err != nil {
			fmt.Println("ERROR: MergePasswdFile Rename", err)
			return
		}

		fmt.Println("Renamed /etc/passwd file, because it was corrupted.", c.String(), err)
		return
	}

	lowerUsers, err := ReadPasswd(vmRoot + "/rootfs/etc/passwd")
	if err != nil {
		fmt.Println("ERROR: MergePasswdFile ReadPasswd", err)
		return
	}

	for uid, user := range lowerUsers {
		users[uid] = user
	}

	err = WritePasswd(users, passwdFile)
	if err != nil {
		fmt.Println("ERROR: MergePasswdFile WritePasswd", err)
		return
	}

	c.AsContainer().Chown(passwdFile)
}

func (c *Container) MergeGroupFile() {
	groupFile := c.Dir + "/overlay/etc/group"
	groups, err := ReadGroup(groupFile) // error ignored
	if err != nil {
		if os.IsNotExist(err) {
			return // no file in upper, no need to merge
		}

		err := os.Rename(groupFile, groupFile+"_corrupt_"+time.Now().Format(time.RFC3339))
		if err != nil {
			fmt.Println("ERROR: MergeGroupFile Rename", err)
			return
		}

		fmt.Println("Renamed /etc/group file, because it was corrupted.", c.String(), err)
		return
	}

	lowerGroups, err := ReadGroup(vmRoot + "/rootfs/etc/group")
	if err != nil {
		fmt.Println("ERROR: MergeGroupFile ReadGroup", err)
		return
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
		fmt.Println("ERROR: MergeGroupFile WriteGroup", err)
		return
	}

	c.AsContainer().Chown(groupFile)
}

func ReadPasswd(fileName string) (users map[int]*SysUser, err error) {
	defer func() {
		if recoveredErr := recover(); recoveredErr != nil {
			err = fmt.Errorf("%v", recoveredErr)
		}
	}()

	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	r := bufio.NewReader(f)

	users = make(map[int]*SysUser, 0)
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

	return
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

func ReadGroup(fileName string) (groups map[int]*SysGroup, err error) {
	defer func() {
		if recoveredErr := recover(); recoveredErr != nil {
			err = fmt.Errorf("%v", recoveredErr)
		}
	}()

	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	r := bufio.NewReader(f)

	groups = make(map[int]*SysGroup, 0)
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

	return
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

func atEndOfFile(r *bufio.Reader) bool {
	_, err := r.ReadByte()
	if err != nil {
		if err == io.EOF {
			return true
		}
		panic(err)
	}
	r.UnreadByte()
	return false
}

func tryReadByte(r *bufio.Reader, b byte) bool {
	c, err := r.ReadByte()
	if err != nil {
		panic(err)
	}
	if c == b {
		return true
	}
	r.UnreadByte()
	return false
}

func readUntil(r *bufio.Reader, delim byte) string {
	line, err := r.ReadString(delim)
	if err != nil {
		panic(err)
	}
	return line[:len(line)-1]
}

func atoi(str string) int {
	i, err := strconv.Atoi(str)
	if err != nil {
		panic(err)
	}
	return i
}

func itoa(i int) string {
	return strconv.Itoa(i)
}
