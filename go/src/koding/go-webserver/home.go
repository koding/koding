package main

import (
	"net/http"
	"sync"
	"time"
)

var (
	TimeoutTime = 3000 * time.Millisecond
)

// HomeHandler renders both loggedin and loggedout page for user.
// When user is loggedin, we send some extra data with the payload
// so the client doesn't need to fetch them after the page loads.
func HomeHandler(w http.ResponseWriter, r *http.Request) {
	userInfo, err := prepareUserInfo(w, r)
	if err != nil {
		writeLoggedOutHomeToResp(w)
		return
	}

	user := NewLoggedInUser()
	user.Set("Group", userInfo.Group)
	user.Set("Username", userInfo.Username)
	user.Set("SessionId", userInfo.ClientId)
	user.Set("Impersonating", userInfo.Impersonating)
	user.Set("UserId", userInfo.UserId)
	user.Set("Account", userInfo.Account)

	wg := &sync.WaitGroup{}
	wg.Add(3)
	go fetchSocial(userInfo, user, wg)
	go fetchEnvData(userInfo, user, wg)
	go fetchRolesAndPermissions(userInfo, user, wg)

	done := make(chan struct{}, 0) // signals when done prefetching items
	go func() {
		wg.Wait()
		close(done)
	}()

	select {
	case <-time.After(TimeoutTime):
		Log.Warning("Loggedin page timedout for user: %s", userInfo.Username)
		writeLoggedInHomeToResp(w, user)
	case <-done:
		writeLoggedInHomeToResp(w, user)
	}
}
