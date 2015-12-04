package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"reflect"
	"runtime"
	"testing"

	"github.com/koding/integration/helpers"
	"github.com/koding/logging"
	"github.com/rjeczalik/gh/webhook"
)

func TestGithubPush(t *testing.T) {
	whd := &webhook.PushEvent{}
	err := json.Unmarshal([]byte(pushTestData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.push(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[baxterthehacker](https://github.com/baxterthehacker) [pushed](https://github.com/baxterthehacker/public-repo/compare/9049f1265b7d...0d1a26e67d8f) to [baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo)
  * [0d1a26](https://github.com/baxterthehacker/public-repo/commit/0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c) Update README.md - baxterthehacker`
	equals(t, exp, d)
}

func TestGithubPushWithoutCommit(t *testing.T) {
	whd := &webhook.PushEvent{}
	err := json.Unmarshal([]byte(pushTestWithoutCommitData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.push(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := ""
	equals(t, exp, d)
}

func TestGithubIssueComment(t *testing.T) {
	whd := &webhook.IssueCommentEvent{}
	err := json.Unmarshal([]byte(issueCommentTestData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.issueComment(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[baxterthehacker](https://github.com/baxterthehacker) [commented](https://github.com/baxterthehacker/public-repo/issues/2#issuecomment-99262140) on issue 'Spelling error in the README file' at [baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo)
>You are totally right! I'll get this fixed right away.`
	equals(t, exp, d)
}

func TestGithubCommitComment(t *testing.T) {
	whd := &webhook.CommitCommentEvent{}
	err := json.Unmarshal([]byte(commitCommentTestData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.commitComment(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[baxterthehacker](https://github.com/baxterthehacker) [commented](https://github.com/baxterthehacker/public-repo/commit/9049f1265b7d61be4a8904a9a27120d2064dab3b#commitcomment-11056394) on commit [9049f1](https://github.com/baxterthehacker/public-repo/commit/9049f1265b7d61be4a8904a9a27120d2064dab3b#commitcomment-11056394) at [baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo)
>This is a really good change! :+1:`
	equals(t, exp, d)
}

func TestGithubCreateBranch(t *testing.T) {
	whd := &webhook.CreateEvent{}
	err := json.Unmarshal([]byte(createBranchData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.create(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := "[mehmetalisavas](https://github.com/mehmetalisavas) created branch `createdBranch` at [mehmetalisavas/webhook](https://github.com/mehmetalisavas/webhook)"
	equals(t, exp, d)
}

func TestGithubDeleteBranch(t *testing.T) {
	whd := &webhook.DeleteEvent{}
	err := json.Unmarshal([]byte(deleteBranchData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.delete(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := "[mehmetalisavas](https://github.com/mehmetalisavas) deleted branch `test4` at [mehmetalisavas/webhook](https://github.com/mehmetalisavas/webhook)"
	equals(t, exp, d)
}

func TestGithubDeleteTag(t *testing.T) {
	whd := &webhook.DeleteEvent{}
	err := json.Unmarshal([]byte(deleteTagData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.delete(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := "[baxterthehacker](https://github.com/baxterthehacker) deleted tag `simple-tag` at [baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo)"
	equals(t, exp, d)
}

func TestGithubPullRequest(t *testing.T) {
	whd := &webhook.PullRequestEvent{}
	err := json.Unmarshal([]byte(pullRequestTestData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.pullRequest(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[baxterthehacker](https://github.com/baxterthehacker) opened pull request [Update the README with new information](https://github.com/baxterthehacker/public-repo/pull/1) at [baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo)`
	equals(t, exp, d)
}

func TestGithubPullRequestAssigned(t *testing.T) {
	whd := &webhook.PullRequestEvent{}
	err := json.Unmarshal([]byte(pullRequestAssignedData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.pullRequest(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[sent-hil](https://github.com/sent-hil) assigned to [sinan](https://github.com/sinan) pull request [updated readme](https://github.com/koding/koding/pull/5667) at [koding/koding](https://github.com/koding/koding)`
	equals(t, exp, d)
}

func TestGithubPullRequestSynchronized(t *testing.T) {
	whd := &webhook.PullRequestEvent{}
	err := json.Unmarshal([]byte(pullRequestSynchronizedData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.pullRequest(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[stefanbc](https://github.com/stefanbc) synchronized pull request [Fixes: Not all elements are aligned in the sidebar [fixes #108226170]](https://github.com/koding/koding/pull/5980) at [koding/koding](https://github.com/koding/koding)`
	equals(t, exp, d)
}

func SkipTestGithubPullRequestMerged(t *testing.T) {
	whd := &webhook.PullRequestEvent{}
	err := json.Unmarshal([]byte(mergePullRequestData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.pullRequest(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[mehmetalisavas](https://github.com/mehmetalisavas) merged pull request [PR actim](https://github.com/mehmetalisavas/webhook/pull/4) at [mehmetalisavas/webhook](https://github.com/mehmetalisavas/webhook)`
	equals(t, exp, d)
}

func SkipTestGithubPrReviewComment(t *testing.T) {
	whd := &webhook.PullRequestReviewCommentEvent{}
	err := json.Unmarshal([]byte(prReviewCommentData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.prReviewComment(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[baxterthehacker](https://github.com/baxterthehacker) [commented](https://github.com/baxterthehacker/public-repo/pull/1#discussion_r29724692) on pull request [Update the README with new information](https://github.com/baxterthehacker/public-repo/pull/1) at [baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo)
>Maybe you should use more emojji on this line.`
	equals(t, exp, d)
}

func SkipTestGithubMember(t *testing.T) {
	whd := &webhook.MemberEvent{}
	err := json.Unmarshal([]byte(memberData), whd)
	if err != nil {
		t.Fatal(err.Error())
	}

	g := GithubListener{}
	d, err := g.member(whd)
	if err != nil {
		t.Fatal(err.Error())
	}
	exp := `[octocat](https://github.com/octocat) is added to [baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo) as collaborator`
	equals(t, exp, d)
}

func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.Fail()
	}
}

func CreateTestGithubService(t *testing.T) Github {
	gc := GithubConfig{}
	gc.PublicURL = "http://koding.com/api/webhook"
	gc.IntegrationUrl = "http://koding.com/api/integration"
	gc.Log = logging.NewLogger("testing")
	gc.Secret = "koding"

	service, err := NewGithub(gc)
	if err != nil {
		t.Fatal(err)
	}

	return service
}

///////////////// Github Configure tests /////////////////////

func createWebhookSettings(serviceId, repo *string) map[string]*string {
	return map[string]*string{
		"serviceId":  serviceId,
		"repository": repo,
	}
}

func createWebhookRequestData(settings, oldSettings map[string]*string, events []string) map[string]interface{} {
	return map[string]interface{}{
		"userToken":    "640e289a912484cdaf79ab55e2534181e0d40ba1",
		"serviceToken": "e4e18128-d0db-487c-6e33-825e6fe6e824",
		"settings":     settings,
		"oldSettings":  oldSettings,
		"events":       events,
	}
}

func doConfigureGithubRequest(t *testing.T, service Github, data map[string]interface{}) (helpers.ConfigureResponse, error) {
	body, err := json.Marshal(data)
	if err != nil {
		t.Errorf("Expected nil, got %s", err)
	}

	reader := bytes.NewReader(body)
	req, _ := http.NewRequest("POST", "/configure/github", reader)

	return service.Configure(req)
}

func TestConfigureInvalidRepository(t *testing.T) {
	service := CreateTestGithubService(t)
	reqData := createWebhookRequestData(nil, nil, nil)

	_, err := doConfigureGithubRequest(t, service, reqData)
	if err != ErrInvalidRepository {
		t.Errorf("Expected %s, got %v", ErrInvalidRepository, err)
	}
}

func TestConfigureCreateWebhook(t *testing.T) {
	service := CreateTestGithubService(t)
	mux := http.NewServeMux()
	server := httptest.NewServer(mux)

	mux.HandleFunc("/repos/canthefason/testing/hooks",
		func(w http.ResponseWriter, r *http.Request) {
			if r.Method != "POST" {
				w.WriteHeader(404)
				return
			}
			w.Header().Set("Content-Type", "application/json")

			fmt.Fprintln(w, createWebhookResponse)
		},
	)
	defer server.Close()
	service.ServerUrl = server.URL

	repo := "canthefason/testing"
	reqData := createWebhookRequestData(createWebhookSettings(nil, &repo), nil, nil)

	res, err := doConfigureGithubRequest(t, service, reqData)
	if err != nil {
		t.Errorf("Expected nil, got %s", err)
	}
	if res["serviceId"].(string) != "5284884" {
		t.Errorf("Expected 5284884, got %d", res["serviceId"])
	}
	events := res["events"].([]interface{})
	if res["events"] == nil || len(events) != 1 {
		t.Errorf("events not found")
	}

}

func TestConfigureUpdateWebhook(t *testing.T) {
	service := CreateTestGithubService(t)
	mux := http.NewServeMux()
	server := httptest.NewServer(mux)

	mux.HandleFunc("/repos/canthefason/testing/hooks/5284884",
		func(w http.ResponseWriter, r *http.Request) {
			if r.Method != "PATCH" {
				w.WriteHeader(404)
				return
			}
			w.Header().Set("Content-Type", "application/json")

			fmt.Fprintln(w, updateWebhookResponse)
		},
	)
	defer server.Close()
	service.ServerUrl = server.URL

	repo := "canthefason/testing"
	serviceId := "5284884"
	reqData := createWebhookRequestData(
		createWebhookSettings(&serviceId, &repo),
		createWebhookSettings(&serviceId, &repo),
		[]string{"push", "commit_comment"},
	)

	res, err := doConfigureGithubRequest(t, service, reqData)
	if err != nil {
		t.Errorf("Expected nil, got %s", err)
	}

	if res["serviceId"].(string) != "5284884" {
		t.Errorf("Expected 5284884, got %d", res["serviceId"])
	}
	events := res["events"].([]interface{})
	if res["events"] == nil || len(events) != 2 {
		t.Errorf("events not found")
	}
}

func TestConfigureChangeWebhookRepo(t *testing.T) {
	service := CreateTestGithubService(t)
	mux := http.NewServeMux()
	server := httptest.NewServer(mux)

	repos := map[string]struct{}{
		"canthefason/account-service": struct{}{},
	}

	mux.HandleFunc("/repos/canthefason/account-service/hooks/5284884",
		func(w http.ResponseWriter, r *http.Request) {
			if r.Method != "DELETE" {
				w.WriteHeader(404)
				return
			}
			delete(repos, "canthefason/account-service")
			w.Header().Set("Content-Type", "application/json")
		},
	)

	mux.HandleFunc("/repos/canthefason/testing/hooks",
		func(w http.ResponseWriter, r *http.Request) {
			if r.Method != "POST" {
				w.WriteHeader(404)
				return
			}
			repos["canthefason/testing"] = struct{}{}
			w.Header().Set("Content-Type", "application/json")

			fmt.Fprintln(w, createWebhookResponse)
		},
	)
	defer server.Close()
	service.ServerUrl = server.URL

	oldRepo := "canthefason/account-service"
	newRepo := "canthefason/testing"
	serviceId := "5284884"
	reqData := createWebhookRequestData(
		createWebhookSettings(nil, &newRepo),
		createWebhookSettings(&serviceId, &oldRepo),
		[]string{"push"},
	)

	res, err := doConfigureGithubRequest(t, service, reqData)
	if err != nil {
		t.Errorf("Expected nil, got %s", err)
	}
	if res["serviceId"].(string) != "5284884" {
		t.Errorf("Expected 5284884, got %d", res["serviceId"])
	}
	events := res["events"].([]interface{})
	if res["events"] == nil || len(events) != 1 {
		t.Errorf("events not found")
	}

	if _, ok := repos["canthefason/account-service"]; ok {
		t.Errorf("old webhook is not deleted")
	}

}
