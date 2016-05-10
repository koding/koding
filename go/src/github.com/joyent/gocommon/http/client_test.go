package http

import (
	"bytes"
	"fmt"
	"io/ioutil"
	gc "launchpad.net/gocheck"
	"net/http"
	"testing"

	httpsuite "github.com/joyent/gocommon/testing"
	"github.com/joyent/gosign/auth"
)

const (
	Signature = "yK0J17CQ04ZvMsFLoH163Sjyg8tE4BoIeCsmKWLQKN3BYgSpR0XyqrecheQ2A0o4L99oSumYSKIscBSiH5rqdf4/1zC/FEkYOI2UzcIHYb1MPNzO3g/5X44TppYE+8dxoH99V+Ts8RT3ZurEYjQ8wmK0TnxdirAevSpbypZJaBOFXUZSxx80m5BD4QE/MSGo/eaVdJI/Iw+nardHNvimVCr6pRNycX1I4FdyRR6kgrAl2NkY2yxx/CAY21Ir+dmbG3A1x4GiIE485LLheAL5/toPo7Gh8G5fkrF9dXWVyX0k9AZXqXNWn5AZxc32dKL2enH09j/X86RtwiR1IEuPww=="
	key       = `-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAyLOtVh8qXjdwfjZZYwkEgg1yoSzmpKKpmzYW745lBGtPH87F
spHVHeqjmgFnBsARsD7CHzYyQTho7oLrAEbuF7tKdGRK25wJIenPKKuL+UVwZNeJ
VEXSiMNmX3Y4IqRteqRIjhw3DmXYHEWvBc2JVy8lWtyK+o6o8jlO0aRTTT2+dETp
yqKqNJyHVNz2u6XVtm7jqyLU7tAqW+qpr5zSoNmuUAyz6JDCRnlWvwp1qzuS1LV3
2HK9yfq8TGriDVPyPRpFRmiRGWGIrIKrmm4sImpoLfuVBITjeh8V3Ee0OCDmTLgY
lTHAmCLFJxaW5Y8b4cTt5pbT7R1iu77RKJo3fwIBIwKCAQEAmtPAOx9bMr0NozE9
pCuHIn9nDp77EUpIUym57AAiCrkuaP6YgnB/1T/6jL9A2VJWycoDdynO/xzjO6bS
iy9nNuDwSyjMCH+vRgwjdyVAGBD+7rTmSFMewUZHqLpIj8CsOgm0UF7opLT3K8C6
N60vbyRepS3KTEIqjvkCSfPLO5Sp38KZYXKg0/Abb21WDSEzWonjV8JfOyMfUYhh
7QCE+Nf8s3b+vxskOuCQq1WHoqo8CqXrMYVknkvnQuRFPuaOLEjMbJVqlTb9ns2V
SKxmo46R7fl2dKgMBll+Nec+3Dn2/Iq/qnHq34HF/rhz0uvQDv1w1cSEMjLQaHtH
yZMkgwKBgQDtIAY+yqcmGFYiHQT7V35QbmfeJX1/v9KgpcA7L9Qi6H2LgKPlZu3e
Fc5Pp8C82uIzxuKBbEqauoWAEfP7r2wn1EwoQGMdsY9MpPiScS5iwLKuiSWyyjyf
Snmq+wLwVMYr71ijCuD+Ydm2xGoYeogwkV+QuTOS79s7HGM5tAN9TQKBgQDYrXHR
Nc84Xt+86cWCXJ2rAhHoTMXQQSVXoc75CjBPM2oUH6iguVBM7dPG0ORU14+o7Q7Y
gUvQCV6xoWH05nESHG++sidRifM/HT07M1bSjbMPcFmeAeA0mTFodXfRN6dKyibb
5kHUHgkgsC8qpXZr1KsNR7BcvC+xKuG1qC1R+wKBgDz5mzS3xJTEbeuDzhS+uhSu
rP6b7RI4o+AqnyUpjlIehq7X76FjnEBsAdn377uIvdLMvebEEy8aBRJNwmVKXaPX
gUwt0FgXtyJWTowOeaRdb8Z7CbGht9EwaG3LhGmvZiiOANl303Sc0ZVltOG5G7S3
qtwSXbgRyqjMyQ7WhI3vAoGBAMYa67f2rtRz/8Kp2Sa7E8+M3Swo719RgTotighD
1GWrWav/sB3rQhpzCsRnNyj/mUn9T2bcnRX58C1gWY9zmpQ3QZhoXnZvf0+ltFNi
I36tcIMk5DixQgQ0Sm4iQalXdGGi4bMbqeaB3HWoZaNVc5XJwPYy6mNqOjuU657F
pcdLAoGBAOQRc5kaZ3APKGHu64DzKh5TOam9J2gpRSD5kF2fIkAeaYWU0bE9PlqV
MUxNRzxbIC16eCKFUoDkErIXGQfIMUOm+aCT/qpoAdXIvuO7H0OYRjMDmbscSDEV
cQYaFsx8Z1KwMVBTwDtiGXhd+82+dKnXxH4bZC+WAKs7L79HqhER
-----END RSA PRIVATE KEY-----`
)

func Test(t *testing.T) {
	gc.TestingT(t)
}

type LoopingHTTPSuite struct {
	httpsuite.HTTPSuite
	creds *auth.Credentials
}

func (s *LoopingHTTPSuite) SetUpSuite(c *gc.C) {
	s.HTTPSuite.SetUpSuite(c)
	authCreds, err := auth.NewAuth("test_user", key, "rsa-sha256")
	c.Assert(err, gc.IsNil)
	s.creds = &auth.Credentials{
		UserAuthentication: authCreds,
		SdcKeyId:           "test_key",
		SdcEndpoint:        auth.Endpoint{URL: "http://gotest.api.joyentcloud.com"},
	}
}

func (s *LoopingHTTPSuite) setupLoopbackRequest() (*http.Header, chan string, *Client) {
	var headers http.Header
	bodyChan := make(chan string, 1)
	handler := func(resp http.ResponseWriter, req *http.Request) {
		headers = req.Header
		bodyBytes, _ := ioutil.ReadAll(req.Body)
		req.Body.Close()
		bodyChan <- string(bodyBytes)
		resp.Header().Add("Content-Length", "0")
		resp.WriteHeader(http.StatusNoContent)
		resp.Write([]byte{})
	}
	s.Mux.HandleFunc("/", handler)
	client := New(s.creds, "", nil)

	return &headers, bodyChan, client
}

type HTTPClientTestSuite struct {
	LoopingHTTPSuite
}

type HTTPSClientTestSuite struct {
	LoopingHTTPSuite
}

var _ = gc.Suite(&HTTPClientTestSuite{})
var _ = gc.Suite(&HTTPSClientTestSuite{})

func (s *HTTPClientTestSuite) assertHeaderValues(c *gc.C, apiVersion string) {
	emptyHeaders := http.Header{}
	date := "Mon, 14 Oct 2013 18:49:29 GMT"
	headers, _ := createHeaders(emptyHeaders, s.creds, "content-type", date, apiVersion, false)
	contentTypes := []string{"content-type"}
	dateHeader := []string{"Mon, 14 Oct 2013 18:49:29 GMT"}
	authorizationHeader := []string{"Signature keyId=\"/test_user/keys/test_key\",algorithm=\"rsa-sha256\" " + Signature}
	headerData := map[string][]string{
		"Date": dateHeader, "Authorization": authorizationHeader,
		"Content-Type": contentTypes, "Accept": contentTypes, "User-Agent": []string{gojoyentAgent()}}
	if apiVersion != "" {
		headerData["X-Api-Version"] = []string{apiVersion}
	}
	expectedHeaders := http.Header(headerData)
	c.Assert(headers, gc.DeepEquals, expectedHeaders)
	c.Assert(emptyHeaders, gc.DeepEquals, http.Header{})
}

func (s *HTTPClientTestSuite) TestCreateHeadersNoApiVersion(c *gc.C) {
	s.assertHeaderValues(c, "")
}

func (s *HTTPClientTestSuite) TestCreateHeadersWithApiVersion(c *gc.C) {
	s.assertHeaderValues(c, "token")
}

func (s *HTTPClientTestSuite) TestCreateHeadersCopiesSupplied(c *gc.C) {
	initialHeaders := make(http.Header)
	date := "Mon, 14 Oct 2013 18:49:29 GMT"
	initialHeaders["Foo"] = []string{"Bar"}
	contentType := contentTypeJSON
	contentTypes := []string{contentType}
	dateHeader := []string{"Mon, 14 Oct 2013 18:49:29 GMT"}
	authorizationHeader := []string{"Signature keyId=\"/test_user/keys/test_key\",algorithm=\"rsa-sha256\" " + Signature}
	headers, _ := createHeaders(initialHeaders, s.creds, contentType, date, "", false)
	// it should not change the headers passed in
	c.Assert(initialHeaders, gc.DeepEquals, http.Header{"Foo": []string{"Bar"}})
	// The initial headers should be in the output
	c.Assert(headers, gc.DeepEquals,
		http.Header{"Foo": []string{"Bar"}, "Date": dateHeader, "Authorization": authorizationHeader,
			"Content-Type": contentTypes, "Accept": contentTypes, "User-Agent": []string{gojoyentAgent()}})
}

func (s *HTTPClientTestSuite) TestBinaryRequestSetsUserAgent(c *gc.C) {
	headers, _, client := s.setupLoopbackRequest()
	req := RequestData{}
	resp := ResponseData{ExpectedStatus: []int{http.StatusNoContent}}
	err := client.BinaryRequest("POST", s.Server.URL, "", &req, &resp)
	c.Assert(err, gc.IsNil)
	agent := headers.Get("User-Agent")
	c.Check(agent, gc.Not(gc.Equals), "")
	c.Check(agent, gc.Equals, gojoyentAgent())
}

func (s *HTTPClientTestSuite) TestJSONRequestSetsUserAgent(c *gc.C) {
	headers, _, client := s.setupLoopbackRequest()
	req := RequestData{}
	resp := ResponseData{ExpectedStatus: []int{http.StatusNoContent}}
	err := client.JsonRequest("POST", s.Server.URL, "", &req, &resp)
	c.Assert(err, gc.IsNil)
	agent := headers.Get("User-Agent")
	c.Check(agent, gc.Not(gc.Equals), "")
	c.Check(agent, gc.Equals, gojoyentAgent())
}

func (s *HTTPClientTestSuite) TestBinaryRequestSetsContentLength(c *gc.C) {
	headers, bodyChan, client := s.setupLoopbackRequest()
	content := "binary\ncontent\n"
	req := RequestData{
		ReqReader: bytes.NewBufferString(content),
		ReqLength: len(content),
	}
	resp := ResponseData{ExpectedStatus: []int{http.StatusNoContent}}
	err := client.BinaryRequest("POST", s.Server.URL, "", &req, &resp)
	c.Assert(err, gc.IsNil)
	encoding := headers.Get("Transfer-Encoding")
	c.Check(encoding, gc.Equals, "")
	length := headers.Get("Content-Length")
	c.Check(length, gc.Equals, fmt.Sprintf("%d", len(content)))
	body, ok := <-bodyChan
	c.Assert(ok, gc.Equals, true)
	c.Check(body, gc.Equals, content)
}

func (s *HTTPClientTestSuite) TestJSONRequestSetsContentLength(c *gc.C) {
	headers, bodyChan, client := s.setupLoopbackRequest()
	reqMap := map[string]string{"key": "value"}
	req := RequestData{
		ReqValue: reqMap,
	}
	resp := ResponseData{ExpectedStatus: []int{http.StatusNoContent}}
	err := client.JsonRequest("POST", s.Server.URL, "", &req, &resp)
	c.Assert(err, gc.IsNil)
	encoding := headers.Get("Transfer-Encoding")
	c.Check(encoding, gc.Equals, "")
	length := headers.Get("Content-Length")
	body, ok := <-bodyChan
	c.Assert(ok, gc.Equals, true)
	c.Check(body, gc.Not(gc.Equals), "")
	c.Check(length, gc.Equals, fmt.Sprintf("%d", len(body)))
}

func (s *HTTPSClientTestSuite) TestDefaultClientRejectSelfSigned(c *gc.C) {
	_, _, client := s.setupLoopbackRequest()
	req := RequestData{}
	resp := ResponseData{ExpectedStatus: []int{http.StatusNoContent}}
	err := client.BinaryRequest("POST", s.Server.URL, "", &req, &resp)
	c.Assert(err, gc.NotNil)
	c.Check(err, gc.ErrorMatches, "(.|\\n)*x509: certificate signed by unknown authority")
}
