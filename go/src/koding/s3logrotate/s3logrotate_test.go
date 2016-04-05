package s3logrotate

import (
	"io/ioutil"
	"os"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestS3LogRotate(t *testing.T) {
	Convey("Given list of files", t, func() {
		Convey("When file is same size as limit", func() {
			Convey("Then it should read from them", func() {
				file1, err := createFileSized("file1", 10)
				So(err, ShouldBeNil)
				defer os.Remove(file1.Name())

				c := New(10, nil, file1.Name())

				content, err := c.ReadFile(file1.Name())
				So(err, ShouldBeNil)
				So(len(content), ShouldEqual, 10)
			})
		})

		Convey("When file is larger than limit", func() {
			Convey("Then it read from end till limit", func() {
				file1, err := createFileSized("file1", 20)
				So(err, ShouldBeNil)
				defer os.Remove(file1.Name())

				c := New(10, nil, file1.Name())

				content, err := c.ReadFile(file1.Name())
				So(err, ShouldBeNil)
				So(len(content), ShouldEqual, 10)
			})
		})

		Convey("When file is smaller than limit", func() {
			Convey("Then it read from end till limit", func() {
				file1, err := createFileSized("file1", 5)
				So(err, ShouldBeNil)
				defer os.Remove(file1.Name())

				c := New(10, nil, file1.Name())

				content, err := c.ReadFile(file1.Name())
				So(err, ShouldBeNil)
				So(len(content), ShouldEqual, 5)
			})
		})

		Convey("Then it should zip them together", func() {
			file1, err := createFileSized("file1", 10)
			So(err, ShouldBeNil)
			defer os.Remove(file1.Name())

			file2, err := createFileSized("file2", 20)
			So(err, ShouldBeNil)
			defer os.Remove(file2.Name())

			c := New(10, nil, file1.Name(), file2.Name())

			content1, err := c.ReadFile(file1.Name())
			So(err, ShouldBeNil)

			content2, err := c.ReadFile(file2.Name())
			So(err, ShouldBeNil)

			f := map[string][]byte{
				file1.Name(): content1,
				file2.Name(): content2,
			}

			_, err = c.Zip(f)
			So(err, ShouldBeNil)
		})

		Convey("Then it should upload them to S3", func() {
		})
	})
}

func createFileSized(name string, size int) (*os.File, error) {
	file, err := ioutil.TempFile("", name)
	if err != nil {
		return nil, err
	}

	content := make([]byte, size)
	for i := 0; i < size; i++ {
		content[i] = 97 // write letter 'a'
	}

	if _, err := file.Write(content); err != nil {
		return nil, err
	}

	if err := file.Close(); err != nil {
		return nil, err
	}

	return file, nil
}
