package services

import (
	"encoding/json"
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"
	"testing"

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
	exp := `[baxterthehacker](https://github.com/baxterthehacker) [pushed](https://github.com/baxterthehacker/public-repo/compare/9049f1265b7d...0d1a26e67d8f) to baxterthehacker/[baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo)
  * [0d1a26](https://github.com/baxterthehacker/public-repo/commit/0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c) Update README.md - baxterthehacker`
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
	exp := `[baxterthehacker](https://github.com/baxterthehacker) [commented](https://github.com/baxterthehacker/public-repo/issues/2#issuecomment-99262140) on pull request 'Spelling error in the README file' at [baxterthehacker/public-repo](https://github.com/baxterthehacker/public-repo)
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

// TODO...

// func TestConfigure(t *testing.T) {
// 	cr := &ConfigureRequest{
// 		AccessToken: "640e289a912484cdaf79ab55e2534181e0d40ba1",
// 		Username:    "mehmetalisavas",
// 		Repo:        "webhook",
// 		Events:      []string{"push", "pull_request"},
// 		Secret:      "koding",
// 	}

// 	by, err := configure(cr)
// 	if err != nil {
// 		t.Fatal(err.Error())
// 	}

// 	fmt.Println(by)

// }
