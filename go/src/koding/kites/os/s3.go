// +build linux

package main

import (
	"errors"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"strings"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"launchpad.net/goamz/aws"
	"launchpad.net/goamz/s3"
)

var (
	s3store = s3.New(
		aws.Auth{
			AccessKey: "AKIAJI6CLCXQ73BBQ2SQ",
			SecretKey: "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",
		},
		aws.USEast,
	)
	uploadsBucket = s3store.Bucket("koding-uploads")
	appsBucket    = s3store.Bucket("koding-apps")
)

func registerS3Methods(k *kite.Kite) {
	registerVmMethod(k, "s3.store", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Name    string
			Content []byte
		}
		if args.Unmarshal(&params) != nil || params.Name == "" || len(params.Content) == 0 || strings.Contains(params.Name, "/") {
			return nil, &kite.ArgumentError{Expected: "{ name: [string], content: [base64 string] }"}
		}

		if len(params.Content) > 2*1024*1024 {
			return nil, errors.New("Content size larger than maximum of 2MB.")
		}

		result, err := uploadsBucket.List(UserAccountId(vos.User).Hex()+"/", "", "", 100)
		if err != nil {
			return nil, err
		}
		if len(result.Contents) >= 100 {
			return nil, errors.New("Maximum of 100 stored files reached.")
		}

		if err := uploadsBucket.Put(UserAccountId(vos.User).Hex()+"/"+params.Name, params.Content, "", s3.Private); err != nil {
			return nil, err
		}
		return true, nil
	})

	registerVmMethod(k, "s3.delete", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Name string
		}
		if args.Unmarshal(&params) != nil || params.Name == "" || strings.Contains(params.Name, "/") {
			return nil, &kite.ArgumentError{Expected: "{ name: [string] }"}
		}
		if err := uploadsBucket.Del(UserAccountId(vos.User).Hex() + "/" + params.Name); err != nil {
			return nil, err
		}
		return true, nil
	})
}

func UserAccountId(user *virt.User) bson.ObjectId {
	var account struct {
		Id bson.ObjectId `bson:"_id"`
	}
	if err := mongodbConn.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": user.Name}).One(&account)
	}); err != nil {
		panic(err)
	}
	return account.Id
}
