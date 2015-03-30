package main

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/go-webserver/utils"
	"net/http"

	"labix.org/v2/mgo/bson"
)

// UserInfo contains the relevant user models and other info required to render
// loggedin page.
type UserInfo struct {
	// ClientId holds the session info of the current requester
	ClientId string

	// Username is the username of the current requester
	Username string

	// SocialApiId holds the id of the current requester in social api
	SocialApiId string

	// UserId holds the mongo user id of the requester
	UserId bson.ObjectId

	// AccountId holds the mongo account id of the requester  - Not sure why we
	// need this ?
	AccountId bson.ObjectId

	// Account holds the account
	Account *models.Account

	// Impersonating holds if the current user is impersonating another one
	Impersonating bool

	// Group holds the current group context for the request
	Group *models.Group
}

// fetchUseInfo fetches different user models and returns UserInfo.  It first
// fetches `clientId` cookie and if it exists, it fetches JSession and other
// info.
func prepareUserInfo(w http.ResponseWriter, r *http.Request, group *models.Group) (*UserInfo, error) {
	subdomain := r.Header.Get("Referer")
	fmt.Println("r.Header-->", r.Header)
	fmt.Println("subdomain-->", subdomain)
	cookie, err := getCookie(w, r)
	if err != nil {
		return nil, err
	}

	clientId := cookie.Value
	session, err := fetchSession(clientId)
	if err != nil {
		expireClientId(w, r)
		return nil, err
	}

	modelhelper.UpdateSessionIP(clientId, utils.GetIpAddress(r))

	username := session.Username

	account, err := fetchAccount(username)
	if err != nil {
		return nil, err
	}

	user, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, err
	}

	userInfo := &UserInfo{
		ClientId:      clientId,
		Username:      username,
		SocialApiId:   account.SocialApiId,
		AccountId:     account.Id,
		UserId:        user.ObjectId,
		Account:       account,
		Impersonating: session.Impersonating,
		Group:         group,
	}

	return userInfo, nil
}

func fetchSession(clientId string) (*models.Session, error) {
	session, err := modelhelper.GetSession(clientId)
	if err != nil {
		return nil, err
	}

	username := session.Username
	if username == "" {
		err := errors.New(
			fmt.Sprintf("Username is empty for session: %s", clientId),
		)

		return nil, err
	}

	return session, nil
}

func fetchAccount(username string) (*models.Account, error) {
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	if account.Type != "registered" {
		err := errors.New(fmt.Sprintf("Account is not registered: %s", username))
		return nil, err
	}

	return account, nil
}
