package gou

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"testing"
	"time"
)

var (
	//finished chan bool
	lastTest time.Time = time.Now()
	stopper  func()    = func() {}
)

// Wait for condition (defined by func) to be true
// this is mostly for testing, but a utility to
// create a ticker checking back every 100 ms to see
// if something (the supplied check func) is done
//
//   WaitFor(func() bool {
//      return ctr.Ct == 0
//   },10)
// timeout (in seconds) is the last arg
func WaitFor(check func() bool, timeoutSecs int) {
	timer := time.NewTicker(100 * time.Millisecond)
	tryct := 0
	for _ = range timer.C {
		if check() {
			timer.Stop()
			break
		}
		if tryct >= timeoutSecs*10 {
			timer.Stop()
			break
		}
		tryct++
	}
}

// Use this in combo with StopCheck() for test functions that must start
// processes such as
func SetStopper(f func()) {
	stopper = f
}

// dumb simple assert for testing, printing
//    Assert(len(items) == 9, t, "Should be 9 but was %d", len(items))
func Assert(is bool, t *testing.T, format string, args ...interface{}) {
	if is == false {
		if logger == nil {
			logger = log.New(os.Stderr, "", log.Ldate|log.Ltime|log.Lshortfile)
			SetErrLogger(logger, "error")
		}
		msg := fmt.Sprintf(format, args...)
		DoLog(3, ERROR, msg)
		t.Fatal(msg)
	}
}

// take two floats, compare, need to be within 2%
func CloseEnuf(a, b float64) bool {
	c := a / b
	if c > .98 && c < 1.02 {
		return true
	}
	return false
}

// take two ints, compare, need to be within 5%
func CloseInt(a, b int) bool {
	c := float64(a) / float64(b)
	if c >= .95 && c <= 1.05 {
		return true
	}
	return false
}

func StartTest() {
	lastTest = time.Now()
}

func StopCheck() {
	t := time.Now()
	if lastTest.Add(time.Millisecond*1000).UnixNano() < t.UnixNano() {
		Log(INFO, "Stopping Test ", lastTest.Unix())
		//finished <- true
		stopper()
		os.Exit(0)
	}
}

// Simple Fetch Wrapper, given a url it returns bytes
func Fetch(url string) (ret []byte, err error) {
	resp, err := http.Get(url)
	defer func() {
		if resp != nil && resp.Body != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		Log(WARN, err.Error())
		return
	}
	ret, err = ioutil.ReadAll(resp.Body)
	if err != nil {
		return
	}
	return
}

// Simple Fetch Wrapper, given a url it returns bytes and response
func FetchResp(url string) (ret []byte, err error, resp *http.Response) {
	resp, err = http.Get(url)
	defer func() {
		if resp != nil && resp.Body != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		Log(WARN, err.Error())
	}
	if resp == nil || resp.Body == nil {
		return
	}
	ret, err = ioutil.ReadAll(resp.Body)
	return
}

// Simple Fetch Wrapper, given a url it returns Helper, error
// Sends as type application/json, interprets whatever datatype is sent in appropriately
func JsonHelperHttp(method, urlStr string, data interface{}) (JsonHelper, error) {
	var body io.Reader
	if data != nil {
		switch val := data.(type) {
		case string:
			body = bytes.NewReader([]byte(val))
		case io.Reader:
			body = val
		case url.Values:
			body = bytes.NewReader([]byte(val.Encode()))
		default:
			by, err := json.Marshal(data)
			if err != nil {
				return nil, err
			}
			body = bytes.NewReader(by)
		}

	}
	req, err := http.NewRequest(method, urlStr, body)
	if err != nil {
		return nil, err
	}
	req.Header.Add("Accept", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	jh, err := NewJsonHelperReader(resp.Body)
	return jh, err
}

// posts an application/json to url with body
// ie:   type = application/json
func PostJson(url, body string) (ret string, err error, resp *http.Response) {
	//Post(url string, bodyType string, body io.Reader)
	buf := bytes.NewBufferString(body)
	resp, err = http.Post(url, "application/json", buf)
	defer func() {
		if resp != nil && resp.Body != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		Log(WARN, err.Error())
		return "", err, resp
	}
	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err, resp
	}

	return string(data), nil, resp
}

// issues http delete an application/json to url with body
func DeleteJson(url, body string) (ret string, err error, resp *http.Response) {
	//Post(url string, bodyType string, body io.Reader)
	buf := bytes.NewBufferString(body)
	Debug(buf.Len())
	req, err := http.NewRequest("DELETE", url, buf)
	if err != nil {
		Debug(err)
		return
	}

	req.Header.Add("Content-Type", "application/json")
	resp, err = http.DefaultClient.Do(req) //(url, "application/json", buf)
	defer func() {
		if resp != nil && resp.Body != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		Log(WARN, err.Error())
		return "", err, resp
	}
	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err, resp
	}

	return string(data), nil, resp
}

// posts a www-form encoded form to url with body
func PostForm(url, body string) (ret string, err error, resp *http.Response) {
	//Post(url string, bodyType string, body io.Reader)
	buf := bytes.NewBufferString(body)
	resp, err = http.Post(url, "application/x-www-form-urlencoded", buf)
	defer func() {
		if resp != nil && resp.Body != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		Log(WARN, url, "  ", body, "    ", err.Error())
		return "", err, resp
	}
	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err, resp
	}

	return string(data), nil, resp
}

// issues http put an application/json to url with optional body
func PutJson(url, body string) (ret string, err error, resp *http.Response) {
	buf := bytes.NewBufferString(body)
	req, err := http.NewRequest("PUT", url, buf)
	if err != nil {
		Debug(err)
		return
	}
	req.Header.Add("Content-Type", "application/json")
	resp, err = http.DefaultClient.Do(req)
	defer func() {
		if resp != nil && resp.Body != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		Log(WARN, err.Error())
		return "", err, resp
	}
	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err, resp
	}

	return string(data), nil, resp
}
