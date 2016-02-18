package main

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"os/user"
	"strings"
	"text/tabwriter"
	"time"

	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/utils/res"

	"golang.org/x/net/context"
)

var defaultUser = "root"

func init() {
	Resources.Register(sshkeyResource)

	if u, err := user.Current(); err == nil {
		defaultUser = u.Username
	}
}

var sshkeyResource = &res.Resource{
	Name:        "sshkey",
	Description: "Manages SSH keys.",
	Commands: map[string]res.Command{
		"list": new(sshkeyList),
		"add":  new(sshkeyAdd),
		"rm":   new(sshkeyRm),
	},
}

// sshkeyList implements a list command
type sshkeyList struct {
	pem   string
	label string
	user  string
}

func (*sshkeyList) Name() string {
	return "list"
}

func (cmd *sshkeyList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.pem, "pem", "", "Filters keys by fingerprint computed from the given key.")
	f.StringVar(&cmd.label, "label", "", "Filters keys by a label.")
	f.StringVar(&cmd.user, "user", "", "Filters keys by a user.")
}

func (cmd *sshkeyList) Run(context.Context) error {
	f := &sl.Filter{
		Label: cmd.label,
		User:  cmd.user,
	}
	if cmd.pem != "" {
		key, err := sl.ParseKey(cmd.pem)
		if err != nil {
			return err
		}
		f.Fingerprint = key.Fingerprint
	}
	keys, err := client.KeysByFilter(f)
	if err != nil {
		return err
	}
	printKeys(keys...)
	return nil
}

// sshkeyAdd implements an add command
type sshkeyAdd struct {
	pem   string
	label string
	user  string
	tags  string
}

func (cmd *sshkeyAdd) Name() string {
	return "add"
}

func (cmd *sshkeyAdd) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.pem, "pem", "", "Private key file.")
	f.StringVar(&cmd.label, "label", "", "Label of the key.")
	f.StringVar(&cmd.user, "user", defaultUser, "Username for which key is created.")
	f.StringVar(&cmd.tags, "tags", "", "Tags to add for the key.")
}

func (cmd *sshkeyAdd) Valid() error {
	if cmd.pem == "" {
		return errors.New("invalid empty value for -pem flag")
	}
	return nil
}

func (cmd *sshkeyAdd) Run(context.Context) error {
	key, err := sl.ParseKey(cmd.pem)
	if err != nil {
		return err
	}
	if cmd.label != "" {
		key.Label = cmd.label
	}
	if cmd.user != "" {
		key.User = cmd.user
	}
	if cmd.tags != "" {
		key.Tags = newTags(strings.Split(cmd.tags, ","))
	}
	key, err = client.CreateKey(key)
	if err != nil {
		return err
	}
	printKeys(key)
	return nil
}

// sshkeyRm implements a rm command
type sshkeyRm struct {
	pem string
	id  int
}

func (*sshkeyRm) Name() string {
	return "rm"
}

func (cmd *sshkeyRm) RegisterFlags(f *flag.FlagSet) {
	f.IntVar(&cmd.id, "id", 0, "Remove public key for the given ID.")
	f.StringVar(&cmd.pem, "pem", "", "Remove public key for the given private key.")
}

func (cmd *sshkeyRm) Run(context.Context) error {
	var ids []int
	if cmd.id != 0 {
		ids = append(ids, cmd.id)
	}
	if cmd.pem != "" {
		key, err := sl.ParseKey(cmd.pem)
		if err != nil {
			return err
		}
		f := &sl.Filter{
			Fingerprint: key.Fingerprint,
		}
		keys, err := client.KeysByFilter(f)
		if err != nil && !sl.IsNotFound(err) {
			return err
		}
		for _, key := range keys {
			ids = append(ids, key.ID)
		}
	}
	if len(ids) == 0 {
		return errors.New("no key found to remove")
	}
	for _, id := range ids {
		if err := client.DeleteKey(id); err != nil {
			return err
		}
		fmt.Println("Removed", id)
	}
	return nil
}

func printKeys(keys ...*sl.Key) {
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 8, 0, '\t', 0)
	fmt.Fprintln(w, "ID\tLabel\tFingerprint\tCreateDate\tUser\tTags")
	for _, key := range keys {
		fmt.Fprintf(w, "%d\t%s\t%s\t%s\t%s\t%s\n", key.ID, key.Label,
			key.Fingerprint, key.CreateDate.Format(time.RFC3339), key.User, key.Tags)
	}
	w.Flush()
}

func newTags(kv []string) sl.Tags {
	if len(kv) == 0 {
		return nil
	}
	t := make(sl.Tags)
	for _, kv := range kv {
		if i := strings.IndexRune(kv, '='); i != -1 {
			t[kv[:i]] = kv[i+1:]
		} else {
			t[kv] = ""
		}
	}
	return t
}
