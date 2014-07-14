// +build linux

package oskite

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"strings"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/s3"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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
	bucketsFunc = map[string]func(*storeParams, *virt.VOS) error{
		"user":   userBucketFunc,
		"groups": groupBucketFunc,
	}
)

type storeParams struct {
	// bucket name
	Bucket string

	// can be user id or group name, defines the path given to the bucket
	Path string

	// filename
	Name string

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
	if params.Path == "" {
		return errors.New("{ path: [string] }")
	}

	// we need this to make sure the user has permission to this group
	group, err := modelhelper.GetGroup(params.Path)
	if err != nil {
		return fmt.Errorf("modelhelper.GetGroup: %s", err)
	}

	account, err := modelhelper.GetAccount(vos.User.Name)
	if err != nil {
		return fmt.Errorf("modelhelper.GetAccount: %s", err)
	}

	selector := modelhelper.Selector{
		"as":         "admin",
		"targetName": "JAccount",
		"targetId":   account.Id,
		"sourceName": "JGroup",
		"sourceId":   group.Id,
	}

	relCount, err := modelhelper.RelationshipCount(selector)
	if err != nil {
		return fmt.Errorf("modelhelper.GetRelationship: %s", err)
	}

	if relCount < 1 {
		return &kite.PermissionError{}
	}

	result, err := groupsBucket.List(params.Path+"/", "", "", 100)
	if err != nil {
		return err
	}

	if len(result.Contents) >= 100 {
		return errors.New("Maximum of 100 stored files reached.")
	}

	err = groupsBucket.Put(params.Path+"/"+params.Name, params.Content, "", s3.Private)
	if err != nil {
		return err
	}

	return nil
}

func s3StoreOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	params := new(storeParams)

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.Name == "" || len(params.Content) == 0 || params.Bucket == "" {
		return nil, &kite.ArgumentError{Expected: "{ name: [string], bucket: [string], content: [base64 string] }"}
	}

	return s3Store(params, vos)
}

func s3Store(params *storeParams, vos *virt.VOS) (interface{}, error) {
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
}

func s3DeleteOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	params := new(storeParams)

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.Name == "" || strings.Contains(params.Name, "/") {
		return nil, &kite.ArgumentError{Expected: "{ name: [string] }"}
	}

	return s3Delete(params, vos)
}

func s3Delete(params *storeParams, vos *virt.VOS) (interface{}, error) {
	if err := uploadsBucket.Del(UserAccountId(vos.User).Hex() + "/" + params.Name); err != nil {
		return nil, err
	}
	return true, nil
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
