package main

import (
	"encoding/json"
	"koding/db/mongodb/modelhelper"
	"log"
	"net/http"

	"labix.org/v2/mgo/bson"
)

type LimitResponse struct {
	CanStart     bool    `json:"can_start"`
	CurrentUsage float64 `json:"current_usage,omitempty"`
	AllowedUsage float64 `json:"allowed_usage,omitempty"`
	Reason       string  `json:"reason,omitempty"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}

func checkerHttp(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	accountId := r.URL.Query().Get("account_id")
	if accountId == "" {
		writeError(w, "", "account_id is required")
		return
	}

	yes := bson.IsObjectIdHex(accountId)
	if !yes {
		writeError(w, accountId, "account_id is not valid")
		return
	}

	account, err := modelhelper.GetAccountById(accountId)
	if err != nil {
		writeError(w, accountId, "account_id is not valid")
		return
	}

	var username = account.Profile.Nickname
	var response = checker(username)

	Log.Info("Returning response: %v for username: %v", response, username)

	js, err := json.Marshal(response)
	if err != nil {
		writeError(w, accountId, err.Error())
		return
	}

	w.Write(js)
}

// iterate through each metric, check if user is over limit for that
// metric, return true if yes, go onto next metric if not
func checker(username string) *LimitResponse {
	for _, metric := range metricsToSave {
		response, err := metric.IsUserOverLimit(username)
		if err != nil {
			log.Println(err)
			continue
		}

		if !response.CanStart {
			return response
		}
	}

	return &LimitResponse{CanStart: true}
}

func writeError(w http.ResponseWriter, accountId, err string) {
	Log.Error("Returning error: %v for accountId: %v", accountId, err)

	js, _ := json.Marshal(ErrorResponse{err})

	w.WriteHeader(500)
	w.Write(js)
}
