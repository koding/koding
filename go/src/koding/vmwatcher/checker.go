package main

import (
	"encoding/json"
	"koding/db/mongodb/modelhelper"
	"net/http"

	"gopkg.in/mgo.v2/bson"
)

type LimitResponse struct {
	CanStart     bool    `json:"canStart"`
	Reason       string  `json:"reason,omitempty"`
	CurrentUsage float64 `json:"currentUsage,omitempty"`
	AllowedUsage float64 `json:"allowedUsage,omitempty"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}

func checkerHTTP(w http.ResponseWriter, r *http.Request) {
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

	Log.Info(
		"Returning response#canStart: %v, for username: %v", response.CanStart, username,
	)

	err = json.NewEncoder(w).Encode(response)
	if err != nil {
		writeError(w, accountId, err.Error())
		return
	}
}

// iterate through each metric, check if user is over limit for that
// metric, return true if yes, go onto next metric if not
func checker(username string) *LimitResponse {
	var AllowedUsage float64
	var CurrentUsage float64

	for _, metric := range metricsToSave {
		response, err := metric.IsUserOverLimit(username, StopLimitKey)
		if err != nil {
			Log.Error(err.Error())
			continue
		}

		if !response.CanStart {
			return response
		}

		if metric.GetName() == NetworkOut {
			AllowedUsage, err = storage.GetUserLimit(username)
			if err != nil {
			    AllowedUsage = NetworkOutLimit
			}
			CurrentUsage, _ = storage.GetScore(metric.GetName(), username)
		}
	}

	return &LimitResponse{CanStart: true, AllowedUsage: AllowedUsage, CurrentUsage: CurrentUsage}
}

func writeError(w http.ResponseWriter, accountId, err string) {
	Log.Error("accountId: %s; error: %s", accountId, err)

	js, _ := json.Marshal(ErrorResponse{err})

	w.WriteHeader(500)
	w.Write(js)
}
