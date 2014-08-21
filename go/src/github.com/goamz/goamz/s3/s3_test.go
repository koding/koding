package s3_test

import (
	"bytes"
	"io/ioutil"
	"net/http"
	"testing"
	"time"

	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/s3"
	"github.com/goamz/goamz/testutil"
	"github.com/motain/gocheck"
)

func Test(t *testing.T) {
	gocheck.TestingT(t)
}

type S struct {
	s3 *s3.S3
}

var _ = gocheck.Suite(&S{})

var testServer = testutil.NewHTTPServer()

func (s *S) SetUpSuite(c *gocheck.C) {
	testServer.Start()
	auth := aws.Auth{AccessKey: "abc", SecretKey: "123"}
	s.s3 = s3.New(auth, aws.Region{Name: "faux-region-1", S3Endpoint: testServer.URL})
}

func (s *S) TearDownSuite(c *gocheck.C) {
	s.s3.AttemptStrategy = s3.DefaultAttemptStrategy
}

func (s *S) SetUpTest(c *gocheck.C) {
	s.s3.AttemptStrategy = aws.AttemptStrategy{
		Total: 300 * time.Millisecond,
		Delay: 100 * time.Millisecond,
	}
}

func (s *S) TearDownTest(c *gocheck.C) {
	testServer.Flush()
}

func (s *S) DisableRetries() {
	s.s3.AttemptStrategy = aws.AttemptStrategy{}
}

// PutBucket docs: http://goo.gl/kBTCu

func (s *S) TestPutBucket(c *gocheck.C) {
	testServer.Response(200, nil, "")

	b := s.s3.Bucket("bucket")
	err := b.PutBucket(s3.Private)
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "PUT")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
}

// Head docs: http://bit.ly/17K1ylI

func (s *S) TestHead(c *gocheck.C) {
	testServer.Response(200, nil, "content")

	b := s.s3.Bucket("bucket")
	resp, err := b.Head("name", nil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "HEAD")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.ContentLength, gocheck.FitsTypeOf, int64(0))
	c.Assert(resp, gocheck.FitsTypeOf, &http.Response{})
}

// DeleteBucket docs: http://goo.gl/GoBrY

func (s *S) TestDelBucket(c *gocheck.C) {
	testServer.Response(204, nil, "")

	b := s.s3.Bucket("bucket")
	err := b.DelBucket()
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "DELETE")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
}

// GetObject docs: http://goo.gl/isCO7

func (s *S) TestGet(c *gocheck.C) {
	testServer.Response(200, nil, "content")

	b := s.s3.Bucket("bucket")
	data, err := b.Get("name")

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(err, gocheck.IsNil)
	c.Assert(string(data), gocheck.Equals, "content")
}

func (s *S) TestURL(c *gocheck.C) {
	testServer.Response(200, nil, "content")

	b := s.s3.Bucket("bucket")
	url := b.URL("name")
	r, err := http.Get(url)
	c.Assert(err, gocheck.IsNil)
	data, err := ioutil.ReadAll(r.Body)
	r.Body.Close()
	c.Assert(err, gocheck.IsNil)
	c.Assert(string(data), gocheck.Equals, "content")

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
}

func (s *S) TestGetReader(c *gocheck.C) {
	testServer.Response(200, nil, "content")

	b := s.s3.Bucket("bucket")
	rc, err := b.GetReader("name")
	c.Assert(err, gocheck.IsNil)
	data, err := ioutil.ReadAll(rc)
	rc.Close()
	c.Assert(err, gocheck.IsNil)
	c.Assert(string(data), gocheck.Equals, "content")

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
}

func (s *S) TestGetNotFound(c *gocheck.C) {
	for i := 0; i < 10; i++ {
		testServer.Response(404, nil, GetObjectErrorDump)
	}

	b := s.s3.Bucket("non-existent-bucket")
	data, err := b.Get("non-existent")

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/non-existent-bucket/non-existent")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	s3err, _ := err.(*s3.Error)
	c.Assert(s3err, gocheck.NotNil)
	c.Assert(s3err.StatusCode, gocheck.Equals, 404)
	c.Assert(s3err.BucketName, gocheck.Equals, "non-existent-bucket")
	c.Assert(s3err.RequestId, gocheck.Equals, "3F1B667FAD71C3D8")
	c.Assert(s3err.HostId, gocheck.Equals, "L4ee/zrm1irFXY5F45fKXIRdOf9ktsKY/8TDVawuMK2jWRb1RF84i1uBzkdNqS5D")
	c.Assert(s3err.Code, gocheck.Equals, "NoSuchBucket")
	c.Assert(s3err.Message, gocheck.Equals, "The specified bucket does not exist")
	c.Assert(s3err.Error(), gocheck.Equals, "The specified bucket does not exist")
	c.Assert(data, gocheck.IsNil)
}

// PutObject docs: http://goo.gl/FEBPD

func (s *S) TestPutObject(c *gocheck.C) {
	testServer.Response(200, nil, "")

	b := s.s3.Bucket("bucket")
	err := b.Put("name", []byte("content"), "content-type", s3.Private, s3.Options{})
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "PUT")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.DeepEquals), []string{""})
	c.Assert(req.Header["Content-Type"], gocheck.DeepEquals, []string{"content-type"})
	c.Assert(req.Header["Content-Length"], gocheck.DeepEquals, []string{"7"})
	//c.Assert(req.Header["Content-MD5"], gocheck.DeepEquals, "...")
	c.Assert(req.Header["X-Amz-Acl"], gocheck.DeepEquals, []string{"private"})
}

func (s *S) TestPutObjectReadTimeout(c *gocheck.C) {
	s.s3.ReadTimeout = 50 * time.Millisecond
	defer func() {
		s.s3.ReadTimeout = 0
	}()

	b := s.s3.Bucket("bucket")
	err := b.Put("name", []byte("content"), "content-type", s3.Private, s3.Options{})

	// Make sure that we get a timeout error.
	c.Assert(err, gocheck.NotNil)

	// Set the response after the request times out so that the next request will work.
	testServer.Response(200, nil, "")

	// This time set the response within our timeout period so that we expect the call
	// to return successfully.
	go func() {
		time.Sleep(25 * time.Millisecond)
		testServer.Response(200, nil, "")
	}()
	err = b.Put("name", []byte("content"), "content-type", s3.Private, s3.Options{})
	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestPutObjectHeader(c *gocheck.C) {
	testServer.Response(200, nil, "")

	b := s.s3.Bucket("bucket")
	err := b.PutHeader(
		"name",
		[]byte("content"),
		map[string][]string{"Content-Type": {"content-type"}},
		s3.Private,
	)
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "PUT")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.DeepEquals), []string{""})
	c.Assert(req.Header["Content-Type"], gocheck.DeepEquals, []string{"content-type"})
	c.Assert(req.Header["Content-Length"], gocheck.DeepEquals, []string{"7"})
	//c.Assert(req.Header["Content-MD5"], gocheck.DeepEquals, "...")
	c.Assert(req.Header["X-Amz-Acl"], gocheck.DeepEquals, []string{"private"})
}

func (s *S) TestPutReader(c *gocheck.C) {
	testServer.Response(200, nil, "")

	b := s.s3.Bucket("bucket")
	buf := bytes.NewBufferString("content")
	err := b.PutReader("name", buf, int64(buf.Len()), "content-type", s3.Private, s3.Options{})
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "PUT")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.DeepEquals), []string{""})
	c.Assert(req.Header["Content-Type"], gocheck.DeepEquals, []string{"content-type"})
	c.Assert(req.Header["Content-Length"], gocheck.DeepEquals, []string{"7"})
	//c.Assert(req.Header["Content-MD5"], gocheck.Equals, "...")
	c.Assert(req.Header["X-Amz-Acl"], gocheck.DeepEquals, []string{"private"})
}

func (s *S) TestPutReaderHeader(c *gocheck.C) {
	testServer.Response(200, nil, "")

	b := s.s3.Bucket("bucket")
	buf := bytes.NewBufferString("content")
	err := b.PutReaderHeader(
		"name",
		buf,
		int64(buf.Len()),
		map[string][]string{"Content-Type": {"content-type"}},
		s3.Private,
	)
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "PUT")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.DeepEquals), []string{""})
	c.Assert(req.Header["Content-Type"], gocheck.DeepEquals, []string{"content-type"})
	c.Assert(req.Header["Content-Length"], gocheck.DeepEquals, []string{"7"})
	//c.Assert(req.Header["Content-MD5"], gocheck.Equals, "...")
	c.Assert(req.Header["X-Amz-Acl"], gocheck.DeepEquals, []string{"private"})
}

// DelObject docs: http://goo.gl/APeTt

func (s *S) TestDelObject(c *gocheck.C) {
	testServer.Response(200, nil, "")

	b := s.s3.Bucket("bucket")
	err := b.Del("name")
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "DELETE")
	c.Assert(req.URL.Path, gocheck.Equals, "/bucket/name")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
}

func (s *S) TestDelMultiObjects(c *gocheck.C) {
	testServer.Response(200, nil, "")

	b := s.s3.Bucket("bucket")
	objects := []s3.Object{s3.Object{Key: "test"}}
	err := b.DelMulti(s3.Delete{
		Quiet:   false,
		Objects: objects,
	})
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "POST")
	c.Assert(req.URL.RawQuery, gocheck.Equals, "delete=")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
	c.Assert(req.Header["Content-MD5"], gocheck.Not(gocheck.Equals), "")
	c.Assert(req.Header["Content-Type"], gocheck.Not(gocheck.Equals), "")
	c.Assert(req.ContentLength, gocheck.Not(gocheck.Equals), "")
}

// Bucket List Objects docs: http://goo.gl/YjQTc

func (s *S) TestList(c *gocheck.C) {
	testServer.Response(200, nil, GetListResultDump1)

	b := s.s3.Bucket("quotes")

	data, err := b.List("N", "", "", 0)
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/quotes/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
	c.Assert(req.Form["prefix"], gocheck.DeepEquals, []string{"N"})
	c.Assert(req.Form["delimiter"], gocheck.DeepEquals, []string{""})
	c.Assert(req.Form["marker"], gocheck.DeepEquals, []string{""})
	c.Assert(req.Form["max-keys"], gocheck.DeepEquals, []string(nil))

	c.Assert(data.Name, gocheck.Equals, "quotes")
	c.Assert(data.Prefix, gocheck.Equals, "N")
	c.Assert(data.IsTruncated, gocheck.Equals, false)
	c.Assert(len(data.Contents), gocheck.Equals, 2)

	c.Assert(data.Contents[0].Key, gocheck.Equals, "Nelson")
	c.Assert(data.Contents[0].LastModified, gocheck.Equals, "2006-01-01T12:00:00.000Z")
	c.Assert(data.Contents[0].ETag, gocheck.Equals, `"828ef3fdfa96f00ad9f27c383fc9ac7f"`)
	c.Assert(data.Contents[0].Size, gocheck.Equals, int64(5))
	c.Assert(data.Contents[0].StorageClass, gocheck.Equals, "STANDARD")
	c.Assert(data.Contents[0].Owner.ID, gocheck.Equals, "bcaf161ca5fb16fd081034f")
	c.Assert(data.Contents[0].Owner.DisplayName, gocheck.Equals, "webfile")

	c.Assert(data.Contents[1].Key, gocheck.Equals, "Neo")
	c.Assert(data.Contents[1].LastModified, gocheck.Equals, "2006-01-01T12:00:00.000Z")
	c.Assert(data.Contents[1].ETag, gocheck.Equals, `"828ef3fdfa96f00ad9f27c383fc9ac7f"`)
	c.Assert(data.Contents[1].Size, gocheck.Equals, int64(4))
	c.Assert(data.Contents[1].StorageClass, gocheck.Equals, "STANDARD")
	c.Assert(data.Contents[1].Owner.ID, gocheck.Equals, "bcaf1ffd86a5fb16fd081034f")
	c.Assert(data.Contents[1].Owner.DisplayName, gocheck.Equals, "webfile")
}

func (s *S) TestListWithDelimiter(c *gocheck.C) {
	testServer.Response(200, nil, GetListResultDump2)

	b := s.s3.Bucket("quotes")

	data, err := b.List("photos/2006/", "/", "some-marker", 1000)
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/quotes/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
	c.Assert(req.Form["prefix"], gocheck.DeepEquals, []string{"photos/2006/"})
	c.Assert(req.Form["delimiter"], gocheck.DeepEquals, []string{"/"})
	c.Assert(req.Form["marker"], gocheck.DeepEquals, []string{"some-marker"})
	c.Assert(req.Form["max-keys"], gocheck.DeepEquals, []string{"1000"})

	c.Assert(data.Name, gocheck.Equals, "example-bucket")
	c.Assert(data.Prefix, gocheck.Equals, "photos/2006/")
	c.Assert(data.Delimiter, gocheck.Equals, "/")
	c.Assert(data.Marker, gocheck.Equals, "some-marker")
	c.Assert(data.IsTruncated, gocheck.Equals, false)
	c.Assert(len(data.Contents), gocheck.Equals, 0)
	c.Assert(data.CommonPrefixes, gocheck.DeepEquals, []string{"photos/2006/feb/", "photos/2006/jan/"})
}

func (s *S) TestExists(c *gocheck.C) {
	testServer.Response(200, nil, "")

	b := s.s3.Bucket("bucket")
	result, err := b.Exists("name")

	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "HEAD")

	c.Assert(err, gocheck.IsNil)
	c.Assert(result, gocheck.Equals, true)
}

func (s *S) TestExistsNotFound404(c *gocheck.C) {
	testServer.Response(404, nil, "")

	b := s.s3.Bucket("bucket")
	result, err := b.Exists("name")

	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "HEAD")

	c.Assert(err, gocheck.IsNil)
	c.Assert(result, gocheck.Equals, false)
}

func (s *S) TestExistsNotFound403(c *gocheck.C) {
	testServer.Response(403, nil, "")

	b := s.s3.Bucket("bucket")
	result, err := b.Exists("name")

	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "HEAD")

	c.Assert(err, gocheck.IsNil)
	c.Assert(result, gocheck.Equals, false)
}
