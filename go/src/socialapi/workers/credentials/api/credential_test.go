package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"socialapi/models"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"
)

var (
	ErrEmptyPath       = errors.New("path is empty")
	ErrEmptyValueFound = errors.New("either KeyId or SecretId is not found")
)

func TestStoreCredentials(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While storing credentials", t, func() {
			ownerAccount, groupChannel, groupName := models.CreateRandomGroupDataWithChecks()

			ownerSes, err := models.FetchOrCreateSession(ownerAccount.Nick, groupName)
			So(err, ShouldBeNil)
			So(ownerSes, ShouldNotBeNil)

			Convey("ENV variables and necessary fields should be set", func() {
				So(os.Getenv("AWS_REGION"), ShouldNotBeNil)
			})
			Convey("storing should be successful", func() {
				c := &Credentials{
					KeyId:    "test-keyId",
					SecretId: "test-secretId",
				}

				byt, err := json.Marshal(c)
				if err != nil {
					fmt.Println("ERR-Marhal", err)
				}

				aa := bytes.NewReader(byt)

				So(uploadHandler("pathName", aa), ShoulBeNil)
			})

		})
	})
}

// Actually, this is not a handler function
// Aim of this function is controlling the credentials if there exists or not
func uploadHandler(path string, r io.Reader) error {
	if path == "" {
		return ErrEmptyPath
	}

	plaintext, err := ioutil.ReadAll(r)
	if err != nil {
		return err
	}

	x := &Credentials{}

	downx := bytes.NewReader(plaintext)
	if err := json.NewDecoder(downx).Decode(x); err != nil {
		return err
	}

	if x.KeyId == "" || x.SecretId == "" {
		return ErrEmptyValueFound
	}

}
