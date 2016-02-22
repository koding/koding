package tigertonic

import (
	"bytes"
	"encoding/base64"
	"errors"
	"fmt"
	"net/http"
)

// HTTPBasicAuth returns an http.Handler that conditionally calls another
// http.Handler if the request includes an Authorization header with a
// username and password that appear in the map of credentials.  Otherwise,
// respond 401 Unauthorized.
func HTTPBasicAuth(
	credentials map[string]string,
	realm string,
	h http.Handler,
) FirstHandler {
	return HTTPBasicAuthFunc(
		func(username, password string) error {
			if p, ok := credentials[username]; !ok || p != password {
				return errors.New("unauthorized")
			}
			return nil
		},
		realm,
		h,
	)
}

// HTTPBasicAuthFunc returns an http.Handler that conditionally calls another
// http.Handler if the request includes an Authorization header with a
// username and password that produce a nil error when passed to the given
// function.  Otherwise, respond 401 Unauthorized.
func HTTPBasicAuthFunc(
	f func(string, string) error,
	realm string,
	h http.Handler,
) FirstHandler {
	header := http.Header{
		"WWW-Authenticate": []string{fmt.Sprintf("Basic realm=\"%s\"", realm)},
	}
	return If(func(r *http.Request) (http.Header, error) {
		username, password, err := httpBasicAuth(r.Header)
		if nil != err {
			return header, err
		}
		if err := f(username, password); nil != err {
			return header, Unauthorized{err}
		}
		return nil, nil
	}, h)
}

func httpBasicAuth(h http.Header) (username, password string, err error) {
	authorization := h.Get("Authorization")
	if 6 > len(authorization) || "Basic " != authorization[:6] {
		err = Unauthorized{errors.New("no HTTP Basic auth specified")}
		return
	}
	buf, err := base64.StdEncoding.DecodeString(authorization[6:])
	if nil != err {
		err = Unauthorized{err}
		return
	}
	i := bytes.IndexByte(buf, ':')
	if -1 == i {
		err = Unauthorized{errors.New("malformed HTTP Basic auth specified")}
		return
	}
	username = string(buf[:i])
	password = string(buf[i+1:])
	return
}
