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
	"github.com/koding/logging"
)

var (
	ErrPathNotFound           = errors.New("required a path name to store keys")
	ErrRequiredValuesNotFound = errors.New("required fields not found to store")
	ErrPathContentNotFound    = errors.New("Path content not found")
)

// KeyValue holds the credentials whatever you want as key-value pair
type KeyValue map[string]interface{}

type SneakerS3 struct {
	*sneaker.Manager
	log logging.Logger
}

// Store stores the given credentials on s3
func (s *SneakerS3) Store(u *url.URL, h http.Header, kv KeyValue, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")

	logger := s.createLogger(context, "Store", pathName, http.StatusBadRequest)

	if pathName == "" {
		return response.NewBadRequestWithLogger(logger, ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequestWithLogger(logger, models.ErrNotLoggedIn)
	}

	if kv == nil {
		return response.NewBadRequestWithLogger(logger, ErrRequiredValuesNotFound)
	}

	// convert credentials to bytes
	byt, err := json.Marshal(kv)
	if err != nil {
		return response.NewBadRequestWithLogger(logger, err)
	}

	// bytes need to imlement io.Reader interface
	// then we can use struct as 2.parameter of manager.Upload function
	aa := bytes.NewReader(byt)

	// if another requeest comes to same pathName, its data will be updated.
	// and new incoming data is gonna override the old data
	err = s.Manager.Upload(pathName, aa)
	if err != nil {
		return response.NewBadRequestWithLogger(logger, err)
	}

	logger = s.createLogger(context, "Store", pathName, http.StatusOK)
	logger.Info("")

	return response.NewOK(nil)
}

func (s *SneakerS3) Get(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")

	logger := s.createLogger(context, "Get", pathName, http.StatusBadRequest)
	if pathName == "" {
		return response.NewBadRequestWithLogger(logger, ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequestWithLogger(logger, models.ErrNotLoggedIn)
	}

	downArray := []string{pathName}
	down, err := s.Manager.Download(downArray)
	if err != nil {
		return response.NewBadRequestWithLogger(logger, err)
	}

	if down[pathName] == nil {
		return response.NewBadRequestWithLogger(logger, ErrPathContentNotFound)
	}

	var kv KeyValue

	downX := bytes.NewReader(down[pathName])
	if err := json.NewDecoder(downX).Decode(&kv); err != nil {
		return response.NewBadRequestWithLogger(logger, err)
	}

	logger = s.createLogger(context, "Get", pathName, http.StatusOK)
	logger.Info("")

	return response.NewOK(kv)
}

func (s *SneakerS3) Delete(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")

	logger := s.createLogger(context, "Delete", pathName, http.StatusBadRequest)

	if pathName == "" {
		return response.NewBadRequestWithLogger(logger, ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequestWithLogger(logger, models.ErrNotLoggedIn)
	}

	err := s.Manager.Rm(pathName)
	if err != nil {
		return response.NewBadRequestWithLogger(logger, err)
	}

	logger = s.createLogger(context, "Delete", pathName, http.StatusAccepted)
	logger.Info("")

	return response.NewDeleted()
}

// createLogger creates the log system for sneaker S3 storage
func (s *SneakerS3) createLogger(context *models.Context, reqType, keyPath string, statusCode int) logging.Logger {
	ctx := s.log.New("SneakerS3")

	if context.IsLoggedIn() {
		return ctx.New("IP", context.Client.IP, "requester", context.Client.Account.Nick, "operation", reqType, "key path", keyPath, "status code", statusCode)
	} else {
		return ctx.New("operation", reqType, "key path", keyPath, "status code", statusCode)
	}
}
