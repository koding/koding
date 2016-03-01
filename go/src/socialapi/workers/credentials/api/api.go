package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"strings"

	"github.com/codahale/sneaker"
)

var (
	ErrPathNotFound           = errors.New("required a path name to store keys")
	ErrRequiredValuesNotFound = errors.New("required fields not found to store")
)

// KeyValue holds the credentials whatever you want as key-value pair
type KeyValue map[string]interface{}

type Credentials struct {
	KeyValues []KeyValue `json:"keyValue"`
}

type SneakerS3 struct {
	*sneaker.Manager
}

// Store stores the given credentials on s3
func (s *SneakerS3) Store(u *url.URL, h http.Header, cr *Credentials, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")
	if pathName == "" {
		return response.NewBadRequest(ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	if cr.KeyValues == nil {
		return response.NewBadRequest(ErrRequiredValuesNotFound)
	}

	// convert credentials to bytes
	byt, err := json.Marshal(cr)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// bytes need to imlement io.Reader interface
	// then we can use struct as 2.parameter of manager.Upload function
	aa := bytes.NewReader(byt)

	// if another requeest comes to same pathName, its data will be updated.
	// and new incoming data is gonna override the old data
	err = s.Manager.Upload(pathName, aa)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(nil)
}

func (s *SneakerS3) Get(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")
	if pathName == "" {
		return response.NewBadRequest(ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	downArray := []string{pathName}
	down, err := s.Manager.Download(downArray)
	if err != nil {
		return response.NewBadRequest(err)
	}

	x := &Credentials{}

	downX := bytes.NewReader(down[pathName])
	if err := json.NewDecoder(downX).Decode(x); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(x)
}

func parseContext(s string) (map[string]string, error) {
	if s == "" {
		return nil, nil
	}

	context := map[string]string{}
	for _, v := range strings.Split(s, ",") {
		parts := strings.SplitN(v, "=", 2)
		if len(parts) != 2 {
			return nil, fmt.Errorf("unable to parse context: %q", v)
		}
		context[parts[0]] = parts[1]
	}
	return context, nil
}
