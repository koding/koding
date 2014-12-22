package main

import (
	"errors"
	"fmt"
	"strings"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/go-webserver/utils"
	"net/http"

	"labix.org/v2/mgo/bson"
)

// UserInfo contains the relevant user models and other info
// required to render loggedin page.
type UserInfo struct {
	ClientId, Username, SocialApiId string
	UserId, AccountId               bson.ObjectId
	Account                         *models.Account
	Impersonating                   bool
}

// fetchUseInfo fetches different user models and returns UserInfo.
// It first fetches `clientId` cookie and if it exists, it fetches
// JSession and other info.
func fetchUserInfo(w http.ResponseWriter, r *http.Request) (*UserInfo, error) {
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
		expireClientId(w, r)
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

	if strings.HasPrefix(username, "guest-") {
		username = "guestuser"
	}

	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	if account.Type != "registered" {
		err := errors.New(fmt.Sprintf("Account is not register: %s", username))
		return nil, err
	}

	return account, nil
}
