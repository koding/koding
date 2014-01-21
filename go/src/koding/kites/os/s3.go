// +build linux

package main

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"strings"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"launchpad.net/goamz/aws"
	"launchpad.net/goamz/s3"
)

const (
	appsBucketName    = "koding-apps"
	uploadsBucketName = "koding-uploads"
	groupsBucketName  = "koding-groups"
)

var (
	s3store = s3.New(
		aws.Auth{
			AccessKey: "AKIAJI6CLCXQ73BBQ2SQ",
			SecretKey: "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",
		},
		aws.USEast,
	)

	// define single buckets
	uploadsBucket = s3store.Bucket(uploadsBucketName)
	appsBucket    = s3store.Bucket(appsBucketName)
	groupsBucket  = s3store.Bucket(groupsBucketName)

	// each bucket should have their own logic
	bucketsFunc = make(map[string]func(*storeParams, *virt.VOS) error)
)

type storeParams struct {
	Name    string // file name
	Bucket  string // bucket name
	ID      string // used to defined the path of bucket file
	Content []byte
}

func userBucketFunc(params *storeParams, vos *virt.VOS) error {
	path := UserAccountId(vos.User).Hex()

	result, err := uploadsBucket.List(path+"/", "", "", 100)
	if err != nil {
		return err
	}

	if len(result.Contents) >= 100 {
		return errors.New("Maximum of 100 stored files reached.")
	}

	err = uploadsBucket.Put(path+"/"+params.Name, params.Content, "", s3.Private)
	if err != nil {
		return err
	}

	return nil
}

func groupBucketFunc(params *storeParams, vos *virt.VOS) error {
	if params.ID == "" {
		return errors.New("{ id: [string] }")
	}

	pathID := bson.ObjectIdHex(params.ID)
	path := pathID.Hex()

	permissions := vos.VM.GetGroupPermissions(pathID)
	if permissions == nil {
		return &kite.PermissionError{}
	}

	result, err := groupsBucket.List(path+"/", "", "", 100)
	if err != nil {
		return err
	}

	if len(result.Contents) >= 100 {
		return errors.New("Maximum of 100 stored files reached.")
	}

	err = groupsBucket.Put(path+"/"+params.Name, params.Content, "", s3.Private)
	if err != nil {
		return err
	}

	return nil
}

func registerS3Methods(k *kite.Kite) {
	bucketsFunc["user"] = userBucketFunc
	bucketsFunc["groups"] = groupBucketFunc

	registerVmMethod(k, "s3.store", true, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		params := new(storeParams)

		if args.Unmarshal(&params) != nil || params.Name == "" || len(params.Content) == 0 || params.Bucket == "" {
			return nil, &kite.ArgumentError{Expected: "{ name: [string], bucket: [string], content: [base64 string] }"}
		}

		if strings.Contains(params.Name, "/") {
			return nil, &kite.ArgumentError{Expected: "{ name should not contain \"/\"}"}
		}

		if len(params.Content) > 2*1024*1024 {
			return nil, errors.New("Content size larger than maximum of 2MB.")
		}

		bucketFunc, ok := bucketsFunc[params.Bucket]
		if !ok {
			return nil, fmt.Errorf("bucket does not exist: '%s'", params.Bucket)
		}

		err := bucketFunc(params, vos)
		if err != nil {
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
	if err := mongodb.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": user.Name}).One(&account)
	}); err != nil {
		panic(err)
	}
	return account.Id
}
