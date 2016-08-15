package main

import (
	"errors"
	"net/http"
	"strings"

	"github.com/ant0ine/go-json-rest/rest"
	"github.com/gorilla/context"
)

type contextKey int

const USERDATA contextKey = 0

func (oauth *oAuthHandler) MiddlewareFunc(handler rest.HandlerFunc) rest.HandlerFunc {
	return func(writer rest.ResponseWriter, request *rest.Request) {

		authHeader := request.Header.Get("Authorization")
		if authHeader == "" {
			oauth.unauthorized(writer)
			return
		}

		token, err := oauth.extractToken(authHeader)
		if err != nil {
			rest.Error(writer, "Missing authentication", http.StatusBadRequest)
			return
		}

		accessData, err := oauth.server.Storage.LoadAccess(token)
		if err != nil {
			rest.Error(writer, "Invalid authentication", http.StatusBadRequest)
			return
		}
		if accessData.Client == nil {
			oauth.unauthorized(writer)
			return
		}
		if accessData.Client.RedirectUri == "" {
			oauth.unauthorized(writer)
			return
		}
		if accessData.IsExpired() {
			oauth.unauthorized(writer)
			return
		}

		context.Set(request.Request, USERDATA, accessData.UserData)

		handler(writer, request)
	}

}

func (oauth *oAuthHandler) extractToken(header string) (string, error) {
	parts := strings.SplitN(header, " ", 2)
	if !(len(parts) == 2 && parts[0] == "Bearer") {
		return "", errors.New("Invalid authentication")
	}

	return parts[1], nil
}

func (oauth *oAuthHandler) unauthorized(writer rest.ResponseWriter) {
	rest.Error(writer, "Not Authorized", http.StatusUnauthorized)
}
