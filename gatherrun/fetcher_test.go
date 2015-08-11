package gatherrun

import (
	"io/ioutil"
	"path/filepath"
	"testing"

	. "github.com/koding/klient/Godeps/_workspace/src/github.com/smartystreets/goconvey/convey"
)

var (
	bucketName = "gather-vm-test"
	binaryName = "gather"
	binaryTar  = "gather.tar"
)

func newTestFetcher() *S3Fetcher {
	return &S3Fetcher{
		AccessKey:  "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey:  "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",
		BucketName: bucketName,
		FileName:   binaryTar,
		Region:     "us-east-1",
	}
}

func TestFetcher(t *testing.T) {
	Convey("Given commmand to download scripts", t, func() {
		Convey("When scripts bucket doesn't exist", func() {
			Convey("Then it should return error", func() {
				fetcher := newTestFetcher()
				fetcher.BucketName = ""

				err := fetcher.Download("")
				So(err, ShouldNotBeNil)
			})
		})

		Convey("When scripts folder doesn't exist", func() {
			Convey("Then it should return error", func() {
				fetcher := newTestFetcher()
				fetcher.FileName = "non-existent.tar"

				err := fetcher.Download("")
				So(err, ShouldNotBeNil)
			})
		})

		Convey("Then it should download scripts folder", func() {
			fetcher := newTestFetcher()

			folderName, err := ioutil.TempDir("", "")
			So(err, ShouldBeNil)

			err = fetcher.Download(folderName)
			So(err, ShouldBeNil)

			isExists, err := exists(filepath.Join(folderName, binaryTar))
			So(err, ShouldBeNil)
			So(isExists, ShouldBeTrue)
		})
	})
}
