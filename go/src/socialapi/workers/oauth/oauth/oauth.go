package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"log"
	"net/http"
	"socialapi/config"

	"gopkg.in/mgo.v2/bson"

	"github.com/RangelReale/osin"
	"github.com/RangelReale/osincli"
	"github.com/koding/runner"
)

const Name = "oauth-example"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	ms := modelhelper.NewOauthStore(modelhelper.Mongo.GetSession())
	id := bson.NewObjectId().Hex()
	client := &osin.DefaultClient{
		Id:          id,
		Secret:      id + "_secret_",
		RedirectUri: "http://dev.koding.com:8070/appauth",
		UserData: map[string]interface{}{
			"foo": "bar",
		},
	}
	if err := ms.SetClient(id, client); err != nil {
		fmt.Println("basladi -1")

		log.Fatalf(err.Error())
	}

	config := &osincli.ClientConfig{
		ClientId:           client.Id,
		ClientSecret:       client.Secret,
		AuthorizeUrl:       "http://dev.koding.com:8090/api/social/oauth/authorize",
		TokenUrl:           "http://dev.koding.com:8090/api/social/oauth/token",
		RedirectUrl:        client.RedirectUri,
		ErrorsInStatusCode: true,
		Scope:              "user_role",
	}
	osincliClient, err := osincli.NewClient(config)
	fmt.Println("basladi -2")

	if err != nil {
		panic(err)
	}
	fmt.Println("basladi -3")

	// create a new request to generate the url
	areq := osincliClient.NewAuthorizeRequest(osincli.CODE)
	areq.CustomParameters["access_type"] = "online"
	areq.CustomParameters["approval_prompt"] = "auto"

	// Home
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		u := areq.GetAuthorizeUrl()

		w.Write([]byte(fmt.Sprintf("<a href=\"%s\">Login</a>", u.String())))
	})

	// Auth endpoint
	http.HandleFunc("/appauth", func(w http.ResponseWriter, r *http.Request) {
		fmt.Println("basladi -4")

		w.Write([]byte(fmt.Sprintf("Write Something here")))
		// parse a token request
		if areqdata, err := areq.HandleRequest(r); err == nil {
			treq := osincliClient.NewAccessRequest(osincli.AUTHORIZATION_CODE, areqdata)

			// show access request url (for debugging only)
			u2 := treq.GetTokenUrl()
			w.Write([]byte(fmt.Sprintf("Access token URL: %s\n", u2.String())))

			// exchange the authorize token for the access token
			ad, er := treq.GetToken()
			if er == nil {
				w.Write([]byte(fmt.Sprintf("Access token: %+v\n\n", ad)))
				// use the token in ad.AccessToken
			} else {
				w.Write([]byte(fmt.Sprintf("ERROR1: %v\n", er)))
			}
		} else {
			w.Write([]byte(fmt.Sprintf("ERROR2: %v\n", err)))
		}
	})
	fmt.Println("basladi -5")
	go http.ListenAndServe(":8070", nil)
	r.Listen()
	r.Wait()
}
