package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"

	"github.com/codahale/sneaker"
)

var (
	ErrPathNotFound           = errors.New("required a path name to store keys")
	ErrRequiredValuesNotFound = errors.New("required fields not found to store")
)

// KeyValue holds the credentials whatever you want as key-value pair
type KeyValue map[string]interface{}

type SneakerS3 struct {
	*sneaker.Manager
}

// Store stores the given credentials on s3
func (s *SneakerS3) Store(u *url.URL, h http.Header, kv KeyValue, context *models.Context) (int, http.Header, interface{}, error) {

	pathName := u.Query().Get("pathName")
	if pathName == "" {
		return response.NewBadRequest(ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	if kv == nil {
		return response.NewBadRequest(ErrRequiredValuesNotFound)
	}

	// convert credentials to bytes
	byt, err := json.Marshal(kv)
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

	var x KeyValue

	downX := bytes.NewReader(down[pathName])
	if err := json.NewDecoder(downX).Decode(&x); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(x)
}

func (s *SneakerS3) Delete(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")
	if pathName == "" {
		return response.NewBadRequest(ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	err := s.Manager.Rm(pathName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDeleted()
}
