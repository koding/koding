package mgostore

import (
	"fmt"
	"math/rand"
	"os"
	"reflect"
	"testing"

	"github.com/RangelReale/osin"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var session *mgo.Session

func init() {
	var err error
	session, err = mgo.Dial(GetenvOrDefault("MONGODB_PORT_27017_TCP_ADDR", "localhost"))
	if err != nil {
		panic(err)
	}
}

func GetenvOrDefault(key, def string) string {
	value := os.Getenv(key)
	if value == "" {
		return def
	}
	return value
}

func initTestStorage() *MongoStorage {
	return New(session, selectUniqueDbName())
}

func selectUniqueDbName() string {
	dbs, err := session.DatabaseNames()
	if err != nil {
		panic(err)
	}
	dbNames := make(map[string]bool)
	for _, name := range dbs {
		dbNames[name] = true
	}
	for {
		newname := fmt.Sprintf("mgostore%d", rand.Int31())
		if !dbNames[newname] {
			return newname
		}
	}
}

func deleteTestDatabase(storage *MongoStorage) {
	err := storage.session.DB(storage.dbName).DropDatabase()
	if err != nil {
		panic(err)
	}
}

func setClient1234(storage *MongoStorage) (*osin.Client, error) {
	client := &osin.Client{
		Id:          "1234",
		Secret:      "aabbccdd",
		RedirectUri: "http://localhost:14000/appauth"}
	err := storage.SetClient(client.Id, client)
	return client, err
}

func TestSetClient(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	_, err := setClient1234(storage)
	if err != nil {
		t.Errorf("setClient failed: %v", err)
	}
}

func TestGetClient(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	client, err := setClient1234(storage)
	if err != nil {
		t.Errorf("setClient returned err: %v", err)
		return
	}
	getClient, err := storage.GetClient(client.Id)
	if err != nil {
		t.Errorf("getClient returned err: %v", err)
		return
	}
	if !reflect.DeepEqual(client, getClient) {
		t.Errorf("TestGet failed, expected: '%+v', got: '%+v'", client, getClient)
	}
}

func saveAuthorization(storage *MongoStorage) (*osin.AuthorizeData, error) {
	client, err := setClient1234(storage)
	if err != nil {
		return &osin.AuthorizeData{}, err
	}
	data := &osin.AuthorizeData{
		Client:      client,
		Code:        "9999",
		ExpiresIn:   3600,
		CreatedAt:   bson.Now(),
		RedirectUri: "http://localhost:14000/appauth",
	}
	err = storage.SaveAuthorize(data)
	return data, err
}

func TestSaveAuthorization(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	_, err := saveAuthorization(storage)
	if err != nil {
		t.Errorf("saveAuthorization returned err: %v", err)
	}
}

func TestLoadAuthorizationNotExisting(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	_, err := storage.LoadAuthorize("fubar")
	if err == nil {
		t.Errorf("LoadAuthorize unexpectedly returned no error")
	}
}

func TestLoadAuthorization(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	data, err := saveAuthorization(storage)
	if err != nil {
		t.Errorf("saveAuthorization returned err: %v", err)
		return
	}
	loadData, err := storage.LoadAuthorize(data.Code)
	if err != nil {
		t.Errorf("loadAuthorization returned err: %v", err)
		return
	}

	if !reflect.DeepEqual(data, loadData) {
		t.Errorf("TestGet failed, expected: '%+v', got: '%+v'", data, loadData)
	}
}

func TestRemoveAuthorizationNonExisting(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	err := storage.RemoveAuthorize("fubar")
	if err == nil {
		t.Errorf("RemoveAuthorization unexpectedly returned no error")
	}
}

func TestRemoveAuthorization(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	data, err := saveAuthorization(storage)
	if err != nil {
		t.Errorf("saveAuthorization returned err: %v", err)
		return
	}
	err = storage.RemoveAuthorize(data.Code)
	loadData, err := storage.LoadAuthorize(data.Code)
	if err == nil {
		t.Errorf("RemoveAuthorization failed to remove data: %v", loadData)
		return
	}
}

func saveAccess(storage *MongoStorage) (*osin.AccessData, error) {
	authData, err := saveAuthorization(storage)
	if err != nil {
		return &osin.AccessData{}, err
	}

	data := &osin.AccessData{
		Client:        authData.Client,
		AuthorizeData: authData,
		AccessToken:   "9999",
		RefreshToken:  "r9999",
		ExpiresIn:     3600,
		CreatedAt:     bson.Now(),
	}

	err = storage.SaveAccess(data)
	return data, err
}

func TestLoadAccessNotExisting(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	_, err := storage.LoadAccess("fubar")
	if err == nil {
		t.Errorf("LoadAccess unexpectedly returned no error")
	}
}

func TestLoadAccess(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	data, err := saveAccess(storage)
	if err != nil {
		t.Errorf("saveAccess returned err: %v", err)
		return
	}
	loadData, err := storage.LoadAccess(data.AccessToken)
	if err != nil {
		t.Errorf("loadAccess returned err: %v", err)
		return
	}
	if !reflect.DeepEqual(data, loadData) {
		t.Errorf("LoadAccess failed, expected: '%+v', got: '%+v'", data, loadData)
	}
}

func TestRemoveAccessNonExisting(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	err := storage.RemoveAccess("fubar")
	if err == nil {
		t.Errorf("RemoveAccess unexpectedly returned no error")
	}
}

func TestRemoveAccess(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	data, err := saveAccess(storage)
	if err != nil {
		t.Errorf("saveAccess returned err: %v", err)
		return
	}
	err = storage.RemoveAccess(data.AccessToken)
	loadData, err := storage.LoadAccess(data.AccessToken)
	if err == nil {
		t.Errorf("RemoveAccess failed to remove data: %v", loadData)
	}
}

func TestLoadRefresh(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	data, err := saveAccess(storage)
	if err != nil {
		t.Errorf("saveAccess returned err: %v", err)
		return
	}
	loadData, err := storage.LoadRefresh(data.RefreshToken)
	if err != nil {
		t.Errorf("loadRefresh returned err: %v", err)
		return
	}
	if !reflect.DeepEqual(data, loadData) {
		t.Errorf("LoadRefresh failed, expected: '%+v', got: '%+v'", data, loadData)
	}
}

func TestRemoveRefreshNonExisting(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	err := storage.RemoveRefresh("fubar")
	if err == nil {
		t.Errorf("RemoveRefresh unexpectedly returned no error")
	}
}

func TestRemoveRefresh(t *testing.T) {
	storage := initTestStorage()
	defer deleteTestDatabase(storage)
	data, err := saveAccess(storage)
	if err != nil {
		t.Errorf("saveAccess returned err: %v", err)
		return
	}
	err = storage.RemoveRefresh(data.RefreshToken)
	loadData, err := storage.LoadAccess(data.RefreshToken)
	if err == nil {
		t.Errorf("RemoveRefresh failed to remove data: %v", loadData)
	}
}
