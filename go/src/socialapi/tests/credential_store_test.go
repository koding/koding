package main

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	credential "socialapi/workers/credentials/api"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestStoreGetDeleteCredentials(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While storing credentials", t, func() {
			Convey("after create  account requirements", func() {
				ownerAccount, _, groupName := models.CreateRandomGroupDataWithChecks()

				ownerSes, err := modelhelper.FetchOrCreateSession(ownerAccount.Nick, groupName)
				So(err, ShouldBeNil)
				So(ownerSes, ShouldNotBeNil)

				pathName := "testcredential"

				Convey("We should be able to store credentials", func() {
					keyValue := make(credential.KeyValue, 0)
					keyValue["test-key"] = "test-value"

					err := rest.StoreCredentialWithAuth(pathName, keyValue, ownerSes.ClientId)
					So(err, ShouldBeNil)
				})
				Convey("We should be able to get credentials after storing", func() {
					res, err := rest.GetCredentialWithAuth(pathName, ownerSes.ClientId)
					So(err, ShouldBeNil)
					So(res, ShouldNotBeNil)
					So(res["test-key"], ShouldEqual, "test-value")

				})
				Convey("We should be able to delete credentials after storing", func() {
					err := rest.DeleteCredentialWithAuth(pathName, ownerSes.ClientId)
					So(err, ShouldBeNil)
				})
				Convey("We should not be able to get credentials after deletion process", func() {
					res, err := rest.GetCredentialWithAuth(pathName, ownerSes.ClientId)
					So(err.Error(), ShouldContainSubstring, "The specified key does not exist")
					So(res, ShouldBeNil)
				})
			})
		})
	})
}
