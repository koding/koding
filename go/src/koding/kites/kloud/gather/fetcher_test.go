package gather

import (
	"io/ioutil"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var (
	bucketName = "gather-vm-metrics-test"
	binaryName = "check"
	binaryTar  = "check.tar"
)

func newTestFetcher() *S3Fetcher {
	return &S3Fetcher{
		AccessKey:  "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey:  "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",
		BucketName: bucketName,
		FileName:   binaryTar,
	}
}

func TestFetcher(t *testing.T) {
	Convey("Given commmand to upload scripts", t, func() {
		fetcher := newTestFetcher()

		Convey("When scripts folder doesn't exist", func() {
			Convey("Then it should return error", func() {
				err := fetcher.Upload("")
				So(err, ShouldEqual, ErrFolderNotFound)
			})
		})

		Convey("Then it should tar folder", func() {
			err := tarFolder(binaryName, binaryTar)
			So(err, ShouldBeNil)

			isExists, err := exists(binaryTar)
			So(err, ShouldBeNil)
			So(isExists, ShouldBeTrue)
		})

		Convey("Then it should upload folder", func() {
			err := fetcher.Upload(binaryName)
			So(err, ShouldBeNil)
		})
	})

	Convey("Given commmand to download scripts", t, func() {
		Convey("When scripts bucket doesn't exist", func() {
			Convey("Then it should return error", func() {
				fetcher := newTestFetcher()
				fetcher.BucketName = ""

				err := fetcher.Download("")
				So(err, ShouldEqual, ErrScriptsFileNotFound)
			})
		})

		Convey("When scripts folder doesn't exist", func() {
			Convey("Then it should return error", func() {
				fetcher := newTestFetcher()
				fetcher.FileName = "non-existent.tar"

				err := fetcher.Download("")
				So(err, ShouldEqual, ErrScriptsFileNotFound)
			})
		})

		Convey("Then it should download scripts folder", func() {
			fetcher := newTestFetcher()

			folderName, err := ioutil.TempDir("", "")
			So(err, ShouldBeNil)

			err = fetcher.Download(folderName)
			So(err, ShouldBeNil)

			isExists, err := exists(folderName + "/" + binaryTar)
			So(err, ShouldBeNil)
			So(isExists, ShouldBeTrue)
		})
	})
}
