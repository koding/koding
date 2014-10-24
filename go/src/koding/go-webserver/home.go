package main

import (
	"net/http"
	"time"
)

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	userInfo, err := fetchUserInfo(w, r)
	if err != nil {
		writeLoggedOutHomeToResp(w)
		return
	}

	onItem := make(chan Item, 0)
	onDone := make(chan *LoggedInUser, 1)
	onError := make(chan error, 1)

	outputter := &Outputter{OnItem: onItem, OnError: onError}

	user := NewLoggedInUser()
	user.Set("Group", kodingGroup)
	user.Set("Impersonating", userInfo.Impersonating)
	user.Set("Username", userInfo.Username)
	user.Set("SessionId", userInfo.ClientId)

	go collectItems(user, onItem, onDone, 4)

	go sendAccount(userInfo.Account, outputter)
	go fetchMachines(userInfo.UserId, outputter)
	go fetchWorkspaces(userInfo.AccountId, outputter)
	go fetchSocial(userInfo.SocialApiId, outputter)

	timer := time.NewTimer(time.Second * 2)

	select {
	case <-onError:
		writeLoggedOutHomeToResp(w)
	case <-timer.C:
		writeLoggedInHomeToResp(w, user)
	case resp := <-onDone:
		writeLoggedInHomeToResp(w, resp)
	}
}

func collectItems(resp *LoggedInUser, onItem <-chan Item, onDone chan<- *LoggedInUser, max int) {
	for i := 1; i <= max; i++ {
		item := <-onItem
		resp.Set(item.Name, item.Data)
	}

	onDone <- resp
}
