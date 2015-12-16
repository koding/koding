package sl

import (
	"bytes"
	"crypto/md5"
	"crypto/rsa"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"
	"time"

	"golang.org/x/crypto/ssh"
)

// Key represents the SoftLayer_Security_Ssh_Key type.
type Key struct {
	ID          int       `json:"id,omitempty"`
	Label       string    `json:"label,omitempty"`
	CreateDate  time.Time `json:"createDate,omitempty"`
	Key         string    `json:"key,omitempty"`
	Fingerprint string    `json:"fingerprint,omitempty"`
	Note        string    `json:"notes,omitempty"`

	Tags        Tags   `json:"-"`
	NotTaggable bool   `json:"-"`
	User        string `json:"-"`
}

// ParseKey reads the given RSA private key and create a public one for it.
func ParseKey(pem string) (*Key, error) {
	p, err := ioutil.ReadFile(pem)
	if err != nil {
		return nil, err
	}
	key, err := ssh.ParseRawPrivateKey(p)
	if err != nil {
		return nil, err
	}
	rsaKey, ok := key.(*rsa.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("%q is not a RSA key", pem)
	}
	pub, err := ssh.NewPublicKey(&rsaKey.PublicKey)
	if err != nil {
		return nil, err
	}
	// Compute key fingerprint.
	var buf bytes.Buffer
	for _, b := range md5.Sum(pub.Marshal()) {
		fmt.Fprintf(&buf, "%0.2x:", b)
	}
	// Use filename without the ".pem" suffix as the initial label.
	label := filepath.Base(pem)
	if strings.HasSuffix(pem, ".pem") {
		label = label[:len(label)-len(".pem")]
	}
	return &Key{
		Label:       label,
		Key:         string(bytes.TrimRight(ssh.MarshalAuthorizedKey(pub), "\n")), // trim newline
		Fingerprint: string(bytes.TrimRight(buf.Bytes(), ":")),                    // trim dangling colon
		Note:        "{}",
		Tags:        make(Tags),
	}, nil
}

func (k *Key) encode() error {
	tags := k.Tags
	if k.User != "" {
		if tags == nil {
			tags = make(Tags)
		}
		tags["user"] = k.User
	}
	if len(tags) == 0 {
		return nil
	}
	p, err := json.Marshal(tags)
	if err != nil {
		return err
	}
	k.Note = string(p)
	return nil
}

func (k *Key) decode() {
	if err := json.Unmarshal([]byte(k.Note), &k.Tags); err != nil {
		k.NotTaggable = true
	}
	if user, ok := k.Tags["user"]; ok {
		k.User = user
		delete(k.Tags, "user")
	}
}

// KeyMask represents objectMask Softlayer API value for the Key type.
var KeyMask = []string{
	"id",
	"label",
	"createDate",
	"key",
	"fingerprint",
	"notes",
}

// Keys is a helper type for a slice of keys that supports filtering.
type Keys []*Key

// ByID returns a key with the given ID.
func (k Keys) ByID(id int) Keys {
	if id == 0 {
		return k
	}
	for _, key := range k {
		if key.ID == id {
			return Keys{key}
		}
	}
	return nil
}

// ByLabel returns keys that match the given name.
func (k Keys) ByLabel(name string) (res Keys) {
	if name == "" {
		return k
	}
	for _, key := range k {
		if key.Label == name {
			res = append(res, key)
		}
	}
	return res
}

// ByUser returns keys attached to the given user.
func (k Keys) ByUser(user string) (res Keys) {
	if user == "" {
		return k
	}
	for _, key := range k {
		if key.User == user {
			res = append(res, key)
		}
	}
	return res
}

// ByFingerprint returns those keys, which match the given fingerprint.
func (k Keys) ByFingerprint(fingerprint string) (res Keys) {
	if fingerprint == "" {
		return k
	}
	for _, key := range k {
		if key.Fingerprint == fingerprint {
			res = append(res, key)
		}
	}
	return res
}

// ByTags returns those keys, whose tags match the given tags.
func (k Keys) ByTags(tags Tags) (res Keys) {
	if len(tags) == 0 {
		return k
	}
	for _, key := range k {
		if key.Tags.Matches(tags) {
			res = append(res, key)
		}
	}
	return res
}

// Filter filters keys by the given filter value.
//
// If f is nil, all k are returned.
func (k Keys) Filter(f *Filter) (res Keys) {
	if f == nil {
		return k
	}
	return k.ByID(f.ID).
		ByLabel(f.Label).
		ByFingerprint(f.Fingerprint).
		ByUser(f.User).
		ByTags(f.Tags)
}

type byCreateDateKey []*Key

func (p byCreateDateKey) Len() int           { return len(p) }
func (p byCreateDateKey) Less(i, j int) bool { return p[i].CreateDate.After(p[j].CreateDate) }
func (p byCreateDateKey) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }
