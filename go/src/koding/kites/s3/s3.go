package main

import (
	"errors"
	"flag"
	"koding/db/mongodb"
	"koding/kite"
	"koding/kite/protocol"
	"koding/tools/s3utils"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"launchpad.net/goamz/s3"
	"strings"
)

type S3 struct {
	uploadsBucket *s3utils.Bucket
}

var port = flag.String("port", "2002", "port to bind itself.")

func main() {
	options := &protocol.Options{
		Kitename: "s3",
		Version:  "1",
		Port:     *port,
	}

	methods := map[string]string{
		"s3.store":  "Store",
		"s3.delete": "Delete",
	}

	s := &S3{
		uploadsBucket: s3utils.NewBucket("koding-uploads"), // TODO: read bucket from config
	}

	k := kite.New(options)
	k.AddMethods(s, methods)
	k.Start()
}

func (s S3) Store(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Name    string
		Content []byte
	}

	if r.Args.Unmarshal(&params) != nil || params.Name == "" {
		return errors.New("{ name: [string], content: [base64 string] }")
	}

	if len(params.Content) == 0 || strings.Contains(params.Name, "/") {
		return errors.New("name can't contain '/'")
	}

	if len(params.Content) > 5*1024*1024 {
		return errors.New("Content size larger than maximum of 5MB.")
	}

	userId, err := UserAccountId(r.Username)

	if err != nil {
		return err
	}

	listResult, err := s.uploadsBucket.List(userId.Hex()+"/", "", "", 10)

	if err != nil {
		return err
	}

	if len(listResult.Contents) >= 10 {
		return errors.New("Maximum of 10 stored files reached.")
	}

	if err := s.uploadsBucket.Put(userId.Hex()+"/"+params.Name, params.Content, "", s3.Private); err != nil {
		return err
	}

	*result = true
	return nil
}

func (s S3) Delete(r *protocol.KiteDnodeRequest, result *bool) error {
	var params struct {
		Name string
	}

	if r.Args.Unmarshal(&params) != nil || params.Name == "" {
		return errors.New("{ name: [string] }")
	}

	if strings.Contains(params.Name, "/") {
		return errors.New("name can't contain '/'")
	}

	userId, err := UserAccountId(r.Username)

	if err != nil {
		return err
	}

	if err := s.uploadsBucket.Del(userId.Hex() + "/" + params.Name); err != nil {
		return err
	}

	*result = true
	return nil
}

func UserAccountId(username string) (*bson.ObjectId, error) {
	var account struct {
		Id bson.ObjectId `bson:"_id"`
	}

	if username == "" {
		return nil, errors.New("Username is blank")
	}

	if err := mongodb.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
	}); err != nil {
		return nil, errors.New("Username not found")
	}

	return &account.Id, nil
}
