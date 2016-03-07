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

func createLog(context *models.Context, operation, path string, code int) string {

	log := fmt.Sprintf("Logged with IP: %v, requester: %s, operation: %s, key path: %s, response code: %d",
		context.Client.IP,
		context.Client.Account.OldId,
		operation,
		path,
		code,
	)
	return log
}

// Store stores the given credentials on s3
func (s *SneakerS3) Store(u *url.URL, h http.Header, kv KeyValue, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")

	detailedLog := createLog(context, "POST", pathName, http.StatusBadRequest)

	if pathName == "" {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, models.ErrNotLoggedIn)
	}

	if kv == nil {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, ErrRequiredValuesNotFound)
	}

	// convert credentials to bytes
	byt, err := json.Marshal(kv)
	if err != nil {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, err)
	}

	// bytes need to imlement io.Reader interface
	// then we can use struct as 2.parameter of manager.Upload function
	aa := bytes.NewReader(byt)

	// if another requeest comes to same pathName, its data will be updated.
	// and new incoming data is gonna override the old data
	err = s.Manager.Upload(pathName, aa)
	if err != nil {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, err)
	}

	detailedLog = createLog(context, "POST", pathName, http.StatusOK)

	s.log.Info(detailedLog)
	return response.NewOK(nil)
}

func (s *SneakerS3) Get(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")
	detailedLog := createLog(context, "GET", pathName, http.StatusBadRequest)
	if pathName == "" {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, models.ErrNotLoggedIn)
	}

	downArray := []string{pathName}
	down, err := s.Manager.Download(downArray)
	if err != nil {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, err)
	}

	if down[pathName] == nil {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, ErrPathContentNotFound)
	}

	var kv KeyValue

	downX := bytes.NewReader(down[pathName])
	if err := json.NewDecoder(downX).Decode(&kv); err != nil {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, err)
	}

	detailedLog = createLog(context, "GET", pathName, http.StatusOK)
	return response.NewOK(kv)
}

func (s *SneakerS3) Delete(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")
	detailedLog := createLog(context, "DELETE", pathName, http.StatusBadRequest)

	if pathName == "" {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, ErrPathNotFound)
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, models.ErrNotLoggedIn)
	}

	err := s.Manager.Rm(pathName)
	if err != nil {
		return response.NewBadRequestWithDetailedLogger(s.log, detailedLog, err)
	}

	detailedLog = createLog(context, "DELETE", pathName, http.StatusOK)
	return response.NewDeleted()
}
