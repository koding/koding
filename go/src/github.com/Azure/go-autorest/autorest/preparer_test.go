package autorest

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"reflect"
	"strconv"
	"testing"

	"github.com/Azure/go-autorest/autorest/mocks"
)

// PrepareDecorators wrap and invoke a Preparer. Most often, the decorator invokes the passed
// Preparer and decorates the response.
func ExamplePrepareDecorator() {
	path := "a/b/c/"
	pd := func() PrepareDecorator {
		return func(p Preparer) Preparer {
			return PreparerFunc(func(r *http.Request) (*http.Request, error) {
				r, err := p.Prepare(r)
				if err == nil {
					if r.URL == nil {
						return r, fmt.Errorf("ERROR: URL is not set")
					}
					r.URL.Path += path
				}
				return r, err
			})
		}
	}

	r, _ := Prepare(&http.Request{},
		WithBaseURL("https://microsoft.com/"),
		pd())

	fmt.Printf("Path is %s\n", r.URL)
	// Output: Path is https://microsoft.com/a/b/c/
}

// PrepareDecorators may also modify and then invoke the Preparer.
func ExamplePrepareDecorator_pre() {
	pd := func() PrepareDecorator {
		return func(p Preparer) Preparer {
			return PreparerFunc(func(r *http.Request) (*http.Request, error) {
				r.Header.Add(http.CanonicalHeaderKey("ContentType"), "application/json")
				return p.Prepare(r)
			})
		}
	}

	r, _ := Prepare(&http.Request{Header: http.Header{}},
		pd())

	fmt.Printf("ContentType is %s\n", r.Header.Get("ContentType"))
	// Output: ContentType is application/json
}

// Create a sequence of three Preparers that build up the URL path.
func ExampleCreatePreparer() {
	p := CreatePreparer(
		WithBaseURL("https://microsoft.com/"),
		WithPath("a"),
		WithPath("b"),
		WithPath("c"))
	r, err := p.Prepare(&http.Request{})
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Println(r.URL)
	}
	// Output: https://microsoft.com/a/b/c
}

// Create and apply separate Preparers
func ExampleCreatePreparer_multiple() {
	params := map[string]interface{}{
		"param1": "a",
		"param2": "c",
	}

	p1 := CreatePreparer(WithBaseURL("https://microsoft.com/"), WithPath("/{param1}/b/{param2}/"))
	p2 := CreatePreparer(WithPathParameters(params))

	r, err := p1.Prepare(&http.Request{})
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	}

	r, err = p2.Prepare(r)
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Println(r.URL)
	}
	// Output: https://microsoft.com/a/b/c/
}

// Create and chain separate Preparers
func ExampleCreatePreparer_chain() {
	params := map[string]interface{}{
		"param1": "a",
		"param2": "c",
	}

	p := CreatePreparer(WithBaseURL("https://microsoft.com/"), WithPath("/{param1}/b/{param2}/"))
	p = DecoratePreparer(p, WithPathParameters(params))

	r, err := p.Prepare(&http.Request{})
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Println(r.URL)
	}
	// Output: https://microsoft.com/a/b/c/
}

// Create and prepare an http.Request in one call
func ExamplePrepare() {
	r, err := Prepare(&http.Request{},
		AsGet(),
		WithBaseURL("https://microsoft.com/"),
		WithPath("a/b/c/"))
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Printf("%s %s", r.Method, r.URL)
	}
	// Output: GET https://microsoft.com/a/b/c/
}

// Create a request for a supplied base URL and path
func ExampleWithBaseURL() {
	r, err := Prepare(&http.Request{},
		WithBaseURL("https://microsoft.com/a/b/c/"))
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Println(r.URL)
	}
	// Output: https://microsoft.com/a/b/c/
}

// Create a request with a custom HTTP header
func ExampleWithHeader() {
	r, err := Prepare(&http.Request{},
		WithBaseURL("https://microsoft.com/a/b/c/"),
		WithHeader("x-foo", "bar"))
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Printf("Header %s=%s\n", "x-foo", r.Header.Get("x-foo"))
	}
	// Output: Header x-foo=bar
}

// Create a request whose Body is the JSON encoding of a structure
func ExampleWithFormData() {
	v := url.Values{}
	v.Add("name", "Rob Pike")
	v.Add("age", "42")

	r, err := Prepare(&http.Request{},
		WithFormData(v))
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	}

	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Printf("Request Body contains %s\n", string(b))
	}
	// Output: Request Body contains age=42&name=Rob+Pike
}

// Create a request whose Body is the JSON encoding of a structure
func ExampleWithJSON() {
	t := mocks.T{Name: "Rob Pike", Age: 42}

	r, err := Prepare(&http.Request{},
		WithJSON(&t))
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	}

	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Printf("Request Body contains %s\n", string(b))
	}
	// Output: Request Body contains {"name":"Rob Pike","age":42}
}

// Create a request from a path with escaped parameters
func ExampleWithEscapedPathParameters() {
	params := map[string]interface{}{
		"param1": "a b c",
		"param2": "d e f",
	}
	r, err := Prepare(&http.Request{},
		WithBaseURL("https://microsoft.com/"),
		WithPath("/{param1}/b/{param2}/"),
		WithEscapedPathParameters(params))
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Println(r.URL)
	}
	// Output: https://microsoft.com/a+b+c/b/d+e+f/
}

// Create a request from a path with parameters
func ExampleWithPathParameters() {
	params := map[string]interface{}{
		"param1": "a",
		"param2": "c",
	}
	r, err := Prepare(&http.Request{},
		WithBaseURL("https://microsoft.com/"),
		WithPath("/{param1}/b/{param2}/"),
		WithPathParameters(params))
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Println(r.URL)
	}
	// Output: https://microsoft.com/a/b/c/
}

// Create a request with query parameters
func ExampleWithQueryParameters() {
	params := map[string]interface{}{
		"q1": "value1",
		"q2": "value2",
	}
	r, err := Prepare(&http.Request{},
		WithBaseURL("https://microsoft.com/"),
		WithPath("/a/b/c/"),
		WithQueryParameters(params))
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	} else {
		fmt.Println(r.URL)
	}
	// Output: https://microsoft.com/a/b/c/?q1=value1&q2=value2
}

func TestCreatePreparerDoesNotModify(t *testing.T) {
	r1 := &http.Request{}
	p := CreatePreparer()
	r2, err := p.Prepare(r1)
	if err != nil {
		t.Errorf("autorest: CreatePreparer failed (%v)", err)
	}
	if !reflect.DeepEqual(r1, r2) {
		t.Errorf("autorest: CreatePreparer without decorators modified the request")
	}
}

func TestCreatePreparerRunsDecoratorsInOrder(t *testing.T) {
	p := CreatePreparer(WithBaseURL("https://microsoft.com/"), WithPath("1"), WithPath("2"), WithPath("3"))
	r, err := p.Prepare(&http.Request{})
	if err != nil {
		t.Errorf("autorest: CreatePreparer failed (%v)", err)
	}
	if r.URL.String() != "https://microsoft.com/1/2/3" {
		t.Errorf("autorest: CreatePreparer failed to run decorators in order")
	}
}

func TestAsContentType(t *testing.T) {
	r, err := Prepare(mocks.NewRequest(), AsContentType("application/text"))
	if err != nil {
		fmt.Printf("ERROR: %v", err)
	}
	if r.Header.Get(headerContentType) != "application/text" {
		t.Errorf("autorest: AsContentType failed to add header (%s=%s)", headerContentType, r.Header.Get(headerContentType))
	}
}

func TestAsFormURLEncoded(t *testing.T) {
	r, err := Prepare(mocks.NewRequest(), AsFormURLEncoded())
	if err != nil {
		fmt.Printf("ERROR: %v", err)
	}
	if r.Header.Get(headerContentType) != mimeTypeFormPost {
		t.Errorf("autorest: AsFormURLEncoded failed to add header (%s=%s)", headerContentType, r.Header.Get(headerContentType))
	}
}

func TestAsJSON(t *testing.T) {
	r, err := Prepare(mocks.NewRequest(), AsJSON())
	if err != nil {
		fmt.Printf("ERROR: %v", err)
	}
	if r.Header.Get(headerContentType) != mimeTypeJSON {
		t.Errorf("autorest: AsJSON failed to add header (%s=%s)", headerContentType, r.Header.Get(headerContentType))
	}
}

func TestWithNothing(t *testing.T) {
	r1 := mocks.NewRequest()
	r2, err := Prepare(r1, WithNothing())
	if err != nil {
		t.Errorf("autorest: WithNothing returned an unexpected error (%v)", err)
	}

	if !reflect.DeepEqual(r1, r2) {
		t.Error("azure: WithNothing modified the passed HTTP Request")
	}
}

func TestWithBearerAuthorization(t *testing.T) {
	r, err := Prepare(mocks.NewRequest(), WithBearerAuthorization("SOME-TOKEN"))
	if err != nil {
		fmt.Printf("ERROR: %v", err)
	}
	if r.Header.Get(headerAuthorization) != "Bearer SOME-TOKEN" {
		t.Errorf("autorest: WithBearerAuthorization failed to add header (%s=%s)", headerAuthorization, r.Header.Get(headerAuthorization))
	}
}

func TestWithUserAgent(t *testing.T) {
	ua := "User Agent Go"
	r, err := Prepare(mocks.NewRequest(), WithUserAgent(ua))
	if err != nil {
		fmt.Printf("ERROR: %v", err)
	}
	if r.UserAgent() != ua || r.Header.Get(headerUserAgent) != ua {
		t.Errorf("autorest: WithUserAgent failed to add header (%s=%s)", headerUserAgent, r.Header.Get(headerUserAgent))
	}
}

func TestWithMethod(t *testing.T) {
	r, _ := Prepare(mocks.NewRequest(), WithMethod("HEAD"))
	if r.Method != "HEAD" {
		t.Error("autorest: WithMethod failed to set HTTP method header")
	}
}

func TestAsDelete(t *testing.T) {
	r, _ := Prepare(mocks.NewRequest(), AsDelete())
	if r.Method != "DELETE" {
		t.Error("autorest: AsDelete failed to set HTTP method header to DELETE")
	}
}

func TestAsGet(t *testing.T) {
	r, _ := Prepare(mocks.NewRequest(), AsGet())
	if r.Method != "GET" {
		t.Error("autorest: AsGet failed to set HTTP method header to GET")
	}
}

func TestAsHead(t *testing.T) {
	r, _ := Prepare(mocks.NewRequest(), AsHead())
	if r.Method != "HEAD" {
		t.Error("autorest: AsHead failed to set HTTP method header to HEAD")
	}
}

func TestAsOptions(t *testing.T) {
	r, _ := Prepare(mocks.NewRequest(), AsOptions())
	if r.Method != "OPTIONS" {
		t.Error("autorest: AsOptions failed to set HTTP method header to OPTIONS")
	}
}

func TestAsPatch(t *testing.T) {
	r, _ := Prepare(mocks.NewRequest(), AsPatch())
	if r.Method != "PATCH" {
		t.Error("autorest: AsPatch failed to set HTTP method header to PATCH")
	}
}

func TestAsPost(t *testing.T) {
	r, _ := Prepare(mocks.NewRequest(), AsPost())
	if r.Method != "POST" {
		t.Error("autorest: AsPost failed to set HTTP method header to POST")
	}
}

func TestAsPut(t *testing.T) {
	r, _ := Prepare(mocks.NewRequest(), AsPut())
	if r.Method != "PUT" {
		t.Error("autorest: AsPut failed to set HTTP method header to PUT")
	}
}

func TestPrepareWithNullRequest(t *testing.T) {
	_, err := Prepare(nil)
	if err == nil {
		t.Error("autorest: Prepare failed to return an error when given a null http.Request")
	}
}

func TestWithFormDataSetsContentLength(t *testing.T) {
	v := url.Values{}
	v.Add("name", "Rob Pike")
	v.Add("age", "42")

	r, err := Prepare(&http.Request{},
		WithFormData(v))
	if err != nil {
		t.Errorf("autorest: WithFormData failed with error (%v)", err)
	}

	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		t.Errorf("autorest: WithFormData failed with error (%v)", err)
	}

	if r.ContentLength != int64(len(b)) {
		t.Errorf("autorest:WithFormData set Content-Length to %v, expected %v", r.ContentLength, len(b))
	}
}

func TestWithBool_SetsTheBody(t *testing.T) {
	r, err := Prepare(&http.Request{},
		WithBool(false))
	if err != nil {
		t.Errorf("autorest: WithBool failed with error (%v)", err)
	}

	s, err := ioutil.ReadAll(r.Body)
	if err != nil {
		t.Errorf("autorest: WithBool failed with error (%v)", err)
	}

	if r.ContentLength != int64(len(fmt.Sprintf("%v", false))) {
		t.Errorf("autorest: WithBool set Content-Length to %v, expected %v", r.ContentLength, int64(len(fmt.Sprintf("%v", false))))
	}

	v, err := strconv.ParseBool(string(s))
	if err != nil || v {
		t.Errorf("autorest: WithBool incorrectly encoded the boolean as %v", s)
	}
}

func TestWithFloat32_SetsTheBody(t *testing.T) {
	r, err := Prepare(&http.Request{},
		WithFloat32(42.0))
	if err != nil {
		t.Errorf("autorest: WithFloat32 failed with error (%v)", err)
	}

	s, err := ioutil.ReadAll(r.Body)
	if err != nil {
		t.Errorf("autorest: WithFloat32 failed with error (%v)", err)
	}

	if r.ContentLength != int64(len(fmt.Sprintf("%v", 42.0))) {
		t.Errorf("autorest: WithFloat32 set Content-Length to %v, expected %v", r.ContentLength, int64(len(fmt.Sprintf("%v", 42.0))))
	}

	v, err := strconv.ParseFloat(string(s), 32)
	if err != nil || float32(v) != float32(42.0) {
		t.Errorf("autorest: WithFloat32 incorrectly encoded the boolean as %v", s)
	}
}

func TestWithFloat64_SetsTheBody(t *testing.T) {
	r, err := Prepare(&http.Request{},
		WithFloat64(42.0))
	if err != nil {
		t.Errorf("autorest: WithFloat64 failed with error (%v)", err)
	}

	s, err := ioutil.ReadAll(r.Body)
	if err != nil {
		t.Errorf("autorest: WithFloat64 failed with error (%v)", err)
	}

	if r.ContentLength != int64(len(fmt.Sprintf("%v", 42.0))) {
		t.Errorf("autorest: WithFloat64 set Content-Length to %v, expected %v", r.ContentLength, int64(len(fmt.Sprintf("%v", 42.0))))
	}

	v, err := strconv.ParseFloat(string(s), 64)
	if err != nil || v != float64(42.0) {
		t.Errorf("autorest: WithFloat64 incorrectly encoded the boolean as %v", s)
	}
}

func TestWithInt32_SetsTheBody(t *testing.T) {
	r, err := Prepare(&http.Request{},
		WithInt32(42))
	if err != nil {
		t.Errorf("autorest: WithInt32 failed with error (%v)", err)
	}

	s, err := ioutil.ReadAll(r.Body)
	if err != nil {
		t.Errorf("autorest: WithInt32 failed with error (%v)", err)
	}

	if r.ContentLength != int64(len(fmt.Sprintf("%v", 42))) {
		t.Errorf("autorest: WithInt32 set Content-Length to %v, expected %v", r.ContentLength, int64(len(fmt.Sprintf("%v", 42))))
	}

	v, err := strconv.ParseInt(string(s), 10, 32)
	if err != nil || int32(v) != int32(42) {
		t.Errorf("autorest: WithInt32 incorrectly encoded the boolean as %v", s)
	}
}

func TestWithInt64_SetsTheBody(t *testing.T) {
	r, err := Prepare(&http.Request{},
		WithInt64(42))
	if err != nil {
		t.Errorf("autorest: WithInt64 failed with error (%v)", err)
	}

	s, err := ioutil.ReadAll(r.Body)
	if err != nil {
		t.Errorf("autorest: WithInt64 failed with error (%v)", err)
	}

	if r.ContentLength != int64(len(fmt.Sprintf("%v", 42))) {
		t.Errorf("autorest: WithInt64 set Content-Length to %v, expected %v", r.ContentLength, int64(len(fmt.Sprintf("%v", 42))))
	}

	v, err := strconv.ParseInt(string(s), 10, 64)
	if err != nil || v != int64(42) {
		t.Errorf("autorest: WithInt64 incorrectly encoded the boolean as %v", s)
	}
}

func TestWithString_SetsTheBody(t *testing.T) {
	r, err := Prepare(&http.Request{},
		WithString("value"))
	if err != nil {
		t.Errorf("autorest: WithString failed with error (%v)", err)
	}

	s, err := ioutil.ReadAll(r.Body)
	if err != nil {
		t.Errorf("autorest: WithString failed with error (%v)", err)
	}

	if r.ContentLength != int64(len("value")) {
		t.Errorf("autorest: WithString set Content-Length to %v, expected %v", r.ContentLength, int64(len("value")))
	}

	if string(s) != "value" {
		t.Errorf("autorest: WithString incorrectly encoded the string as %v", s)
	}
}

func TestWithJSONSetsContentLength(t *testing.T) {
	r, err := Prepare(&http.Request{},
		WithJSON(&mocks.T{Name: "Rob Pike", Age: 42}))
	if err != nil {
		t.Errorf("autorest: WithJSON failed with error (%v)", err)
	}

	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		t.Errorf("autorest: WithJSON failed with error (%v)", err)
	}

	if r.ContentLength != int64(len(b)) {
		t.Errorf("autorest:WithJSON set Content-Length to %v, expected %v", r.ContentLength, len(b))
	}
}

func TestWithHeaderAllocatesHeaders(t *testing.T) {
	r, err := Prepare(mocks.NewRequest(), WithHeader("x-foo", "bar"))
	if err != nil {
		t.Errorf("autorest: WithHeader failed (%v)", err)
	}
	if r.Header.Get("x-foo") != "bar" {
		t.Errorf("autorest: WithHeader failed to add header (%s=%s)", "x-foo", r.Header.Get("x-foo"))
	}
}

func TestWithPathCatchesNilURL(t *testing.T) {
	_, err := Prepare(&http.Request{}, WithPath("a"))
	if err == nil {
		t.Errorf("autorest: WithPath failed to catch a nil URL")
	}
}

func TestWithEscapedPathParametersCatchesNilURL(t *testing.T) {
	_, err := Prepare(&http.Request{}, WithEscapedPathParameters(map[string]interface{}{"foo": "bar"}))
	if err == nil {
		t.Errorf("autorest: WithEscapedPathParameters failed to catch a nil URL")
	}
}

func TestWithPathParametersCatchesNilURL(t *testing.T) {
	_, err := Prepare(&http.Request{}, WithPathParameters(map[string]interface{}{"foo": "bar"}))
	if err == nil {
		t.Errorf("autorest: WithPathParameters failed to catch a nil URL")
	}
}

func TestWithQueryParametersCatchesNilURL(t *testing.T) {
	_, err := Prepare(&http.Request{}, WithQueryParameters(map[string]interface{}{"foo": "bar"}))
	if err == nil {
		t.Errorf("autorest: WithQueryParameters failed to catch a nil URL")
	}
}

func TestModifyingExistingRequest(t *testing.T) {
	r, err := Prepare(mocks.NewRequestForURL("https://bing.com"), WithPath("search"), WithQueryParameters(map[string]interface{}{"q": "golang"}))
	if err != nil {
		t.Errorf("autorest: Preparing an existing request returned an error (%v)", err)
	}
	if r.URL.String() != "https://bing.com/search?q=golang" {
		t.Errorf("autorest: Preparing an existing request failed (%s)", r.URL)
	}
}

func TestWithAuthorizer(t *testing.T) {
	r1 := mocks.NewRequest()

	na := &NullAuthorizer{}
	r2, err := Prepare(r1,
		na.WithAuthorization())
	if err != nil {
		t.Errorf("autorest: NullAuthorizer#WithAuthorization returned an unexpected error (%v)", err)
	} else if !reflect.DeepEqual(r1, r2) {
		t.Errorf("autorest: NullAuthorizer#WithAuthorization modified the request -- received %v, expected %v", r2, r1)
	}
}
