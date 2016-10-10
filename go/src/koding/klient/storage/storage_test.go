package storage

import (
	"errors"
	"log"
	"os"
	"os/user"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
)

var exampleData = struct {
	Key   string
	Value string
}{
	Key:   "gopher",
	Value: "koding",
}

var (
	storageKite *kite.Kite

	// remote defines a remote user calling the storageKite kite
	remote *kite.Client
)

func init() {
	storageKite = kite.New("storageKite", "0.0.1")
	storageKite.Config.DisableAuthentication = true
	storageKite.Config.Port = 3637

	u, err := user.Current()
	if err != nil {
		panic(err)
	}

	db, err := openBoltDb(filepath.Join(u.HomeDir, "/.config/koding/klient.bolt"))
	if err != nil {
		log.Println("Can't use BoltDB: ", err)
	}

	s := New(db)

	storageKite.HandleFunc("get", s.GetValue)
	storageKite.HandleFunc("set", s.SetValue)
	storageKite.HandleFunc("delete", s.DeleteValue)

	go storageKite.Run()
	<-storageKite.ServerReadyNotify()

	remoteKite := kite.New("remote", "0.0.1")
	remoteKite.Config.Username = u.Username
	remote = remoteKite.NewClient("http://127.0.0.1:3637/kite")
	err = remote.Dial()
	if err != nil {
		log.Fatalf("err")
	}
}

func TestSet(t *testing.T) {
	resp, err := remote.Tell("set", struct {
		Key   string
		Value string
	}{
		Key:   exampleData.Key,
		Value: exampleData.Value,
	})

	if err != nil {
		t.Fatal(err)
	}

	b, err := resp.Bool()
	if err != nil {
		t.Fatal(err)
	}

	if !b {
		t.Error("set method should return true, got false")
	}
}

func TestGet(t *testing.T) {
	resp, err := remote.Tell("get", struct {
		Key string
	}{
		Key: exampleData.Key,
	})

	if err != nil {
		t.Fatal(err)
	}

	s, err := resp.String()
	if err != nil {
		t.Fatal(err)
	}

	if s != exampleData.Value {
		t.Errorf("set: wrong value fetched.\nWant: '%s'\nGot: '%s'\n", exampleData.Value, s)
	}
}

func TestDelete(t *testing.T) {
	resp, err := remote.Tell("delete", struct {
		Key string
	}{
		Key: exampleData.Key,
	})
	if err != nil {
		t.Fatal(err)
	}

	b, err := resp.Bool()
	if err != nil {
		t.Fatal(err)
	}

	if !b {
		t.Error("delete method should return true, got false")
	}

	resp, err = remote.Tell("get", struct {
		Key string
	}{
		Key: exampleData.Key,
	})

	if err == nil {
		t.Fatal("get: should return an error, got nil")
	}

	if err != nil {
		if !strings.Contains(err.Error(), "key not found") {
			t.Error(err)
		}
	}
}

func openBoltDb(dbpath string) (*bolt.DB, error) {
	if dbpath == "" {
		return nil, errors.New("DB path is empty")
	}

	if err := os.MkdirAll(filepath.Dir(dbpath), 0755); err != nil {
		return nil, err
	}

	return bolt.Open(dbpath, 0644, &bolt.Options{Timeout: 5 * time.Second})
}
