package gather

import (
	"io/ioutil"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func getFetcher() *S3Fetcher {
	return &S3Fetcher{
		AccessKey:  "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey:  "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",
		BucketName: DEFAULT_BUCKET_NAME,
	}
}

var testScriptFolder = "test-scripts"

func TestFetcher(t *testing.T) {
	Convey("Given commmand to upload scripts", t, func() {
		fetcher := getFetcher()

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

			err = exists(tarFile)
			So(err, ShouldBeNil)
		})

		Convey("Then it should upload folder", func() {
			err := fetcher.Upload(testScriptFolder)
			So(err, ShouldBeNil)
		})
	})

	Convey("Given commmand to download scripts", t, func() {
		fetcher := getFetcher()
		fetcher.BucketName = ""

		Convey("When scripts bucket doesn't exist", func() {
			Convey("Then it should return error", func() {
				err := fetcher.Download("")
				So(err, ShouldEqual, ErrScriptsFileNotFound)
			})
		})

		Convey("When scripts folder doesn't exist", func() {
			Convey("Then it should return error", func() {
				err := fetcher.Download("")
				So(err, ShouldEqual, ErrScriptsFileNotFound)
			})
		})

		Convey("Then it should download scripts folder", func() {
			fetcher.BucketName = "gather-vm-metrics"
			fetcher.ScriptsFile = "test-scripts.tar"

			folderName, err := ioutil.TempDir("", "")
			So(err, ShouldBeNil)

			err = fetcher.Download(folderName)
			So(err, ShouldBeNil)

			err = exists(folderName + "/test-scripts.tar")
			So(err, ShouldBeNil)
		})
	})
}
