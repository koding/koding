package helpers

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

var (
	ErrInvalidToken = errors.New("invalid token")
	ErrUserNotFound = errors.New("account is not participant of the channel")
	ErrBodyNotSet   = errors.New("body is not set")
)

func setup(t *testing.T, fn func(s *httptest.Server)) {
	mux := http.NewServeMux()
	server := httptest.NewServer(mux)
	defer server.Close()
	mux.HandleFunc("/botchannel/token/user/someuser", ErrorHandler(ErrInvalidToken))
	mux.HandleFunc("/botchannel/validtoken/user/someuser", ErrorHandler(ErrUserNotFound))

	mux.HandleFunc("/botchannel/validtoken/user/floydpepper",
		func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			response := `{"data":{"channelId":"42"}, "error":null, "status":true}`
			w.Write([]byte(response))
		})

	fn(server)
}

func ErrorHandler(err error) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		NewBadRequest(w, err)
	}
}

func setupPush(t *testing.T, fn func(s *httptest.Server)) {
	mux := http.NewServeMux()
	server := httptest.NewServer(mux)
	defer server.Close()
	mux.HandleFunc("/push/invalidtoken", ErrorHandler(ErrInvalidToken))
	mux.HandleFunc("/push/validtoken",
		func(w http.ResponseWriter, r *http.Request) {
			pr := new(PushRequest)
			err := json.NewDecoder(r.Body).Decode(pr)
			if err != nil {
				NewBadRequest(w, err)
				return
			}
			if pr.Body == "" {
				NewBadRequest(w, ErrBodyNotSet)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			response := `{"data":null, "status":true}`
			w.Write([]byte(response))

		})

	mux.HandleFunc("/botchannel/validtoken/user/floydpepper",
		func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			response := `{"data":{"channelId":"42"}, "error":null, "status":true}`
			w.Write([]byte(response))
		})

	fn(server)
}

func TestFetchBotChannelIntegration(t *testing.T) {
	setup(t, func(server *httptest.Server) {
		// test unknown user case
		_, err := FetchBotChannelId("someuser", "token", server.URL)
		if err == nil || err.Error() != ErrInvalidToken.Error() {
			t.Fatalf("expected '%s' error but got '%v'", ErrInvalidToken, err)
		}

		// test invalid token case
		_, err = FetchBotChannelId("someuser", "validtoken", server.URL)
		if err == nil || err.Error() != ErrUserNotFound.Error() {
			t.Fatalf("expected '%s' error but got '%s'", ErrUserNotFound, err)
		}

		// test valid username and token pair
		id, err := FetchBotChannelId("floydpepper", "validtoken", server.URL)
		if err != nil {
			t.Errorf("expected nil but got '%s'", err)
		}

		if id != 42 {
			t.Errorf("expected 42 as channel id but got %d", id)
		}
	})
}

func TestPush(t *testing.T) {
	setupPush(t, func(s *httptest.Server) {
		pr := &PushRequest{}
		token := "invalidtoken"

		err := Push(token, pr, s.URL)
		if err == nil || err.Error() != ErrInvalidToken.Error() {
			t.Errorf("expected '%s' but got '%v'", ErrInvalidToken, err)
		}

		token = "validtoken"
		err = Push(token, pr, s.URL)
		if err == nil || err.Error() != ErrBodyNotSet.Error() {
			t.Errorf("expected '%s' but got '%v'", ErrBodyNotSet, err)
		}
		pr.Body = "bodyshape"

		err = Push(token, pr, s.URL)
		if err != nil {
			t.Errorf("unexpected error: '%s'", err)
		}
	})
}

func NewBadRequest(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusBadRequest)
	response := `{"description":"` + err.Error() + `", "error":"koding.BadRequest"}`
	w.Write([]byte(response))

}
