package main

import (
	"koding/db/mongodb/modelhelper"
	"net/http"
	"time"
)

func TokenConfirmHandler(w http.ResponseWriter, r *http.Request) {
	claims, err := validateJWTToken(r)
	if err != nil {
		Log.Error("Request to /mail/confirm failed: %s", err)

		w.WriteHeader(500)
		return
	}

	username := claims["username"].(string)

	// fetch account to make sure account wasn't deleted after the
	// token was generated and sent in an email
	_, err = modelhelper.GetAccount(username)
	if err != nil {
		Log.Error("Request to /mail/confirm failed: %s", err)

		w.WriteHeader(500)
		return
	}

	err = modelhelper.ConfirmUser(username)
	if err != nil {
		Log.Error("Request to /mail/confirm failed: %s", err)

		w.WriteHeader(500)
		return
	}

	session, err := modelhelper.CreateSessionForAccount(username, "koding")
	if err != nil {
		Log.Error("Request to /mail/confirm failed: %s", err)

		w.WriteHeader(500)
		return
	}

	cookie := &http.Cookie{
		Name:    "clientId",
		Value:   session.ClientId,
		Path:    "/",
		Secure:  false,
		Expires: time.Now().Add(time.Hour * 24 * 14),
	}

	http.SetCookie(w, cookie)

	redirectUrl := r.URL.Query().Get("redirect_url")
	if redirectUrl == "" {
		redirectUrl = "/"
	}

	http.Redirect(w, r, redirectUrl, 301)
}
