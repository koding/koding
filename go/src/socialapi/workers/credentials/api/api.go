package main

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

type Credentials struct {
	KeyId    string `json:"keyId"`
	SecretId string `json:"secretId"`
}

type S3 struct {
	*sneaker.Manager
}

// Store stores the given credentials on s3
func (s *S3) Store(u *url.URL, h http.Header, cr *Credentials, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")
	if pathName == "" {
		response.NewBadRequest(errors.New("required a path name to store keys"))
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	session, err := models.Cache.Session.ById(context.Client.SessionID)
	if err != nil {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	// convert credentials to bytes
	byt, err := json.Marshal(cr)
	if err != nil {
		response.NewBadRequest(err)
	}

	// bytes need to imlement io.Reader interface
	// then we can use struct as 2.parameter of manager.Upload function
	aa := bytes.NewReader(byt)

	// if another requeest comes to same pathName, its data will be updated.
	// and new incoming data is gonna override the old data
	err = manager.Upload(pathName, aa)
	if err != nil {
		response.NewBadRequest(err)
	}

	response.NewOK(nil)
}

func (s *S3) Get(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	pathName := u.Query().Get("pathName")
	if pathName == "" {
		response.NewBadRequest(errors.New("required a path name to store keys"))
	}

	if !context.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	session, err := models.Cache.Session.ById(context.Client.SessionID)
	if err != nil {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	downArray := []string{pathName}
	down, err := manager.Download(downArray)
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

//
// type CR struct {
// 	Name string
// 	Key  string
// }
//
// func main() {
// 	manager := loadManager()
// 	// fmt.Println("manager is:", manager)
// 	files, err := manager.List("")
// 	if err != nil {
// 		fmt.Println("ERR-List", err)
// 	}
//
// 	fmt.Println("FILES ARE:", files)
// 	path := "mehmetali"
//
// 	c := &CR{
// 		Name: "mehmetalisavas",
// 		Key:  "ag984wshviasv9y7yevoyO&AYf&YFVOYeovofe",
// 	}
//
// 	byt, err := json.Marshal(c)
// 	if err != nil {
// 		fmt.Println("ERR-Marhal", err)
// 	}
//
// 	aa := bytes.NewReader(byt)
//
// 	err = manager.Upload(path, aa)
// 	if err != nil {
// 		fmt.Println("ERR-List", err)
// 	}
//
// 	downArray := []string{path}
// 	down, err := manager.Download(downArray)
// 	if err != nil {
// 		fmt.Println("ERR-Download", err)
// 	}
// 	q := string(down[path])
// 	fmt.Println("DOWN IS :", q)
//
// 	x := &CR{}
//
// 	downX := bytes.NewReader(down[path])
// 	if err := json.NewDecoder(downX).Decode(x); err != nil {
// 		fmt.Println("ERR-Decoder", err)
// 	}
//
// 	a := string(down[path])
//
// 	fmt.Println("Down is :", a)
//
// 	fmt.Println("KEY IS :", x.Key)
// 	fmt.Println("NAME IS :", x.Name)
//
// }
//
// func loadManager() *sneaker.Manager {
// 	// s3://kodingdev-credentials/secrets/
// 	u, err := url.Parse("s3://kodingdev-credentials/secrets/")
// 	if err != nil {
// 		log.Fatalf("bad SNEAKER_S3_PATH: %s", err)
// 	}
// 	if u.Path != "" && u.Path[0] == '/' {
// 		u.Path = u.Path[1:]
// 	}
//
// 	ctxt, err := parseContext("")
// 	if err != nil {
// 		log.Fatalf("bad SNEAKER_MASTER_CONTEXT: %s", err)
// 	}
//
// 	return &sneaker.Manager{
// 		Objects: s3.New(session.New()),
// 		Envelope: sneaker.Envelope{
// 			KMS: kms.New(session.New()),
// 		},
// 		Bucket:            u.Host,
// 		Prefix:            u.Path,
// 		EncryptionContext: ctxt,
// 		KeyId:             "3adede2a-ac33-4532-b63a-c25536c3ba8a",
// 	}
// }
//
// func parseContext(s string) (map[string]string, error) {
// 	if s == "" {
// 		return nil, nil
// 	}
//
// 	context := map[string]string{}
// 	for _, v := range strings.Split(s, ",") {
// 		parts := strings.SplitN(v, "=", 2)
// 		if len(parts) != 2 {
// 			return nil, fmt.Errorf("unable to parse context: %q", v)
// 		}
// 		context[parts[0]] = parts[1]
// 	}
// 	return context, nil
// }
