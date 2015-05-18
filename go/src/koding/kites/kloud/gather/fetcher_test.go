package gather

import (
	"io/ioutil"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func getTestFetcher() *S3Fetcher {
	return &S3Fetcher{
		AccessKey:   "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey:   "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",
		BucketName:  DEFAULT_BUCKET_NAME,
		ScriptsFile: "test-scripts.tar",
	}
}

var testScriptFolder = "test-scripts"

func TestFetcher(t *testing.T) {
	Convey("Given commmand to upload scripts", t, func() {
		fetcher := getTestFetcher()

		Convey("When scripts folder doesn't exist", func() {
			Convey("Then it should return error", func() {
				err := fetcher.Upload("")
				So(err, ShouldEqual, ErrFolderNotFound)
			})
		})

		Convey("Then it should tar folder", func() {
			tarFile := testScriptFolder + ".tar"

			err := tarFolder(testScriptFolder, tarFile)
			So(err, ShouldBeNil)

			isExists, err := exists(tarFile)
			So(err, ShouldBeNil)
			So(isExists, ShouldBeTrue)
		})

		Convey("Then it should upload folder", func() {
			err := fetcher.Upload(testScriptFolder)
			So(err, ShouldBeNil)
		})
	})

	Convey("Given commmand to download scripts", t, func() {
		Convey("When scripts bucket doesn't exist", func() {
			Convey("Then it should return error", func() {
				fetcher := getTestFetcher()
				fetcher.BucketName = ""

				err := fetcher.Download("")
				So(err, ShouldEqual, ErrScriptsFileNotFound)
			})
		})

		Convey("When scripts folder doesn't exist", func() {
			Convey("Then it should return error", func() {
				fetcher := getTestFetcher()
				fetcher.ScriptsFile = "non-existent.tar"

				err := fetcher.Download("")
				So(err, ShouldEqual, ErrScriptsFileNotFound)
			})
		})

		Convey("Then it should download scripts folder", func() {
			fetcher := getTestFetcher()

			folderName, err := ioutil.TempDir("", "")
			So(err, ShouldBeNil)

			err = fetcher.Download(folderName)
			So(err, ShouldBeNil)

			isExists, err := exists(folderName + "/test-scripts.tar")
			So(err, ShouldBeNil)
			So(isExists, ShouldBeTrue)
		})
	})
}
