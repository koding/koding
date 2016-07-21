package services

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"

	"github.com/koding/integration/helpers"
	"github.com/koding/logging"
	"github.com/rjeczalik/gh/webhook"
	"golang.org/x/net/context"
)

const (
	GITHUB           = "github"
	GithubServerURL  = "https://api.github.com"
	OrgEndpoint      = "/users/%s/orgs"
	UserRepoEndpoint = "/user/repos"
	OrgRepoEndpoint  = "/orgs/%s/repos"

	hookType      = "web"
	githubInfoKey = "githubInfo"
)

var (
	ErrInvalidRepository = errors.New("invalid repository")
	ErrWebhookNotDeleted = errors.New("webhook not deleted")
	ErrServiceIdNotSet   = errors.New("service id is not set")
)

type GithubConfig struct {
	Secret         string
	ServerUrl      string
	PublicURL      string
	IntegrationUrl string
	Log            logging.Logger
}

// Github is the main struct for handling all
// github related integrations
type Github struct {
	GithubConfig

	handler *webhook.Handler
}

// GithubListener used for handling github events
type GithubListener struct {
	GithubConfig
	Log logging.Logger
}

type ConfigurePostRequest struct {
	Id     int64    `json:"id"`
	Name   string   `json:"name"`
	Active bool     `json:"active"`
	Events []string `json:"events"`
	Config *Config  `json:"config"`
}

type Config struct {
	URL         string `json:"url"`
	ContentType string `json:"content_type"`
	Secret      string `json:"secret"`
}

type GithubInfo struct {
	token     string
	eventType string
}

func NewGithub(conf GithubConfig) (Github, error) {
	if conf.ServerUrl == "" {
		conf.ServerUrl = GithubServerURL
	}

	var log logging.Logger
	if conf.Log != nil {
		log = conf.Log
	} else {
		log = logging.NewLogger(GITHUB)
	}

	gl := GithubListener{
		GithubConfig: conf,
		Log:          log,
	}

	if conf.Secret == "" {
		return Github{}, errors.New("no github secret provided")
	}

	wh := webhook.New(conf.Secret, gl)
	wh.ContextFunc = githubContextCreator

	gh := Github{
		GithubConfig: conf,
		handler:      wh,
	}

	return gh, nil
}

func (g Github) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	g.handler.ServeHTTP(w, req)
}

// Configure is for supporting CRUD operations on repository webhooks
// in github. It decides what to do by comparing old and new settings
func (g Github) Configure(req *http.Request) (helpers.ConfigureResponse, error) {
	cr := new(helpers.ConfigureRequest)
	if err := helpers.MapConfigureRequest(req, cr); err != nil {
		return nil, err
	}

	repo := cr.Settings.GetString("repository")
	if repo == "" {
		return nil, ErrInvalidRepository
	}

	oldRepo := cr.OldSettings.GetString("repository")

	// configure same repository, therefore update webhook
	if repo == oldRepo {
		baseUrl := fmt.Sprintf("%s/repos/%s/hooks", g.ServerUrl, oldRepo)
		serviceId := cr.OldSettings.GetString("serviceId")
		if serviceId == "" {
			return nil, ErrServiceIdNotSet
		}
		url := fmt.Sprintf("%s/%s", baseUrl, serviceId)

		return g.configure(cr, "PATCH", url)
	}

	// now create the new webhook
	url := fmt.Sprintf("%s/repos/%s/hooks", g.ServerUrl, repo)

	createRes, err := g.configure(cr, "POST", url)
	if err != nil {
		return nil, err
	}

	// repository name has changed, therefore delete the previous webhook
	if oldRepo != "" {
		baseUrl := fmt.Sprintf("%s/repos/%s/hooks", g.ServerUrl, oldRepo)
		serviceId := cr.OldSettings.GetString("serviceId")
		if serviceId == "" {
			return nil, ErrServiceIdNotSet
		}

		url := fmt.Sprintf("%s/%s", baseUrl, serviceId)
		if _, err := g.configure(cr, "DELETE", url); err != nil {
			g.Log.Error("Could not delete the previous repository %s: %s", oldRepo, err)
		}
	}

	return createRes, nil
}

func (g Github) configure(cr *helpers.ConfigureRequest, method, url string) (helpers.ConfigureResponse, error) {
	events, err := helpers.UnmarshalEvents(cr.Settings)
	if err != nil {
		g.Log.Error("Could not unmarshal events", err)
	}

	cpr := &ConfigurePostRequest{
		Name:   hookType,
		Events: events,
		Active: true,
		Config: &Config{
			URL:         prepareEndpoint(g.PublicURL, GITHUB, cr.ServiceToken),
			ContentType: "json",
			Secret:      g.Secret,
		},
	}

	by, err := json.Marshal(cpr)
	if err != nil {
		return nil, err
	}
	reader := bytes.NewReader(by)

	req, err := http.NewRequest(method, url, reader)
	if err != nil {
		return nil, err
	}

	// Set user's oauth token
	headerAuth := fmt.Sprintf("token %s", cr.UserToken)
	req.Header.Add("Authorization", headerAuth)
	c := new(http.Client)
	resp, err := c.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		return nil, errors.New(resp.Status)
	}

	result := make(map[string]interface{})
	// it is delete request with no content
	if resp.ContentLength == 0 {
		return nil, nil
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	response := helpers.ConfigureResponse{}
	response["serviceId"] = strconv.FormatInt(int64(result["id"].(float64)), 10)
	response["events"] = result["events"]

	return response, nil
}

func githubContextCreator(req *http.Request) context.Context {
	token := req.URL.Query().Get("token")
	event := req.Header.Get("X-Github-Event")
	gi := &GithubInfo{
		token:     token,
		eventType: event,
	}

	return context.WithValue(context.Background(), githubInfoKey, gi)
}

// Push is triggered when a repository branch is pushed to.
// For detailed info https://developer.github.com/v3/activity/events/types/#pushevent
func (g GithubListener) Push(ctx context.Context, e *webhook.PushEvent) {
	d, err := g.push(e)
	if err != nil {
		g.Log.Error("failed to parse push data: %+v, err: %s", e, err.Error())
		return
	}

	g.output(ctx, d)
}

func (g GithubListener) push(e *webhook.PushEvent) (string, error) {
	user := fmt.Sprintf("[%s](%s)", e.Sender.Login, e.Sender.HTMLURL)
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)
	compareStr := fmt.Sprintf("[pushed](%s)", e.Compare)
	commitsStr := ""

	if len(e.Commits) < 1 {
		return "", nil
	}

	// limit our commit count
	commitsLen := len(e.Commits)
	if commitsLen > 6 {
		commitsLen = 6
	}

	for _, commit := range e.Commits[:commitsLen] {
		commitsStr += fmt.Sprintf("\n  * [%s](%s) %s - %s", commit.ID[:6], commit.URL, commit.Message, commit.Author.Name)
	}
	return fmt.Sprintf("%s %s to %s%s",
		user,
		compareStr,
		repo,
		commitsStr,
	), nil
}

// IssueComment is triggered when an issue comment is created.
// For detailed info https://developer.github.com/v3/activity/events/types/#issuecommentevent
func (g GithubListener) IssueComment(ctx context.Context, e *webhook.IssueCommentEvent) {
	d, err := g.issueComment(e)
	if err != nil {
		g.Log.Error("failed to parse issue comment data: %+v, err: %s", e, err.Error())
		return
	}

	g.output(ctx, d)
}

func (g GithubListener) issueComment(e *webhook.IssueCommentEvent) (string, error) {
	Link := fmt.Sprintf("[commented](%s)", e.Comment.HTMLURL)
	user := fmt.Sprintf("[%s](%s)", e.Comment.User.Login, e.Comment.User.HTMLURL)
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)

	return fmt.Sprintf("%s %s on issue '%s' at %s\n>%s",
		user,
		Link,
		e.Issue.Title,
		repo,
		e.Comment.Body,
	), nil
}

// CommitComment is triggered when a commit comment is created.
// For detailed info https://developer.github.com/v3/activity/events/types/#commitcommentevent
func (g GithubListener) CommitComment(ctx context.Context, e *webhook.CommitCommentEvent) {
	d, err := g.commitComment(e)
	if err != nil {
		g.Log.Error("failed to parse commit comment data: %+v, err: %s", e, err.Error())
		return
	}

	g.output(ctx, d)
}

func (g GithubListener) commitComment(e *webhook.CommitCommentEvent) (string, error) {
	commit := fmt.Sprintf("[%s](%s)", e.Comment.CommitID[:6], e.Comment.HTMLURL)
	user := fmt.Sprintf("[%s](%s)", e.Comment.User.Login, e.Comment.User.HTMLURL)
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)
	comment := fmt.Sprintf("[commented](%s)", e.Comment.HTMLURL)

	return fmt.Sprintf("%s %s on commit %s at %s\n>%s",
		user,
		comment,
		commit,
		repo,
		e.Comment.Body,
	), nil
}

// PRReviewComment is triggered when a comment is created on a portion of the unified diff of a pull request.
// For detailed info https://developer.github.com/v3/activity/events/types/#pullrequestreviewcommentevent
func (g GithubListener) PRReviewComment(ctx context.Context, e *webhook.PullRequestReviewCommentEvent) {
	d, err := g.prReviewComment(e)
	if err != nil {
		g.Log.Error("failed to parse pr comment data: %+v, err: %s", e, err.Error())
		return
	}

	g.output(ctx, d)
}

func (g GithubListener) prReviewComment(e *webhook.PullRequestReviewCommentEvent) (string, error) {
	pr := fmt.Sprintf("[%s](%s)", e.PullRequest.Title, e.PullRequest.HTMLURL)
	user := fmt.Sprintf("[%s](%s)", e.PullRequest.User.Login, e.PullRequest.User.HTMLURL)
	comment := fmt.Sprintf("[commented](%s)", e.Comment.HTMLURL)
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)

	return fmt.Sprintf("%s %s on pull request %s at %s \n>%s",
		user,
		comment,
		pr,
		repo,
		e.Comment.Body,
	), nil
}

// PullRequest is triggered when a pull request is
// assigned, unassigned, labeled, unlabeled, opened, closed, reopened, or synchronized.
// For detailed info https://developer.github.com/v3/activity/events/types/#pullrequestevent
func (g GithubListener) PullRequest(ctx context.Context, e *webhook.PullRequestEvent) {
	d, err := g.pullRequest(e)
	if err != nil {
		g.Log.Error("failed to parse pull request data: %+v, err: %s", e, err.Error())
		return
	}

	g.output(ctx, d)
}

func (g GithubListener) pullRequest(e *webhook.PullRequestEvent) (string, error) {
	user := fmt.Sprintf("[%s](%s)", e.Sender.Login, e.Sender.HTMLURL)
	pr := fmt.Sprintf("[%s](%s)", e.PullRequest.Title, e.PullRequest.HTMLURL)
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)

	action := e.Action

	if action == "assigned" {
		return g.pullRequestAssigned(e)
	}

	if action == "closed" && e.PullRequest.Merged {
		action = "merged"
	}

	if action == "synchronize" {
		action = "synchronized"
	}

	return fmt.Sprintf("%s %s pull request %s at %s",
		user,
		action,
		pr,
		repo,
	), nil
}

// pullRequestAssigned uses different mentioning from other pull request events
func (g GithubListener) pullRequestAssigned(e *webhook.PullRequestEvent) (string, error) {
	user := fmt.Sprintf("[%s](%s)", e.Sender.Login, e.Sender.HTMLURL)
	pr := fmt.Sprintf("[%s](%s)", e.PullRequest.Title, e.PullRequest.HTMLURL)
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)
	assignee := fmt.Sprintf("[%s](%s)", e.Assignee.Login, e.Assignee.HTMLURL)

	return fmt.Sprintf("%s %s to %s pull request %s at %s",
		user,
		e.Action,
		assignee,
		pr,
		repo,
	), nil
}

// Member is triggered when a user is added as a collaborator to a repository.
// For detailed info https://developer.github.com/v3/activity/events/types/#memberevent
func (g GithubListener) Member(ctx context.Context, e *webhook.MemberEvent) {
	d, err := g.member(e)
	if err != nil {
		g.Log.Error("failed to parse member data: %+v, err: %s", e, err.Error())
		return
	}

	g.output(ctx, d)
}

func (g GithubListener) member(e *webhook.MemberEvent) (string, error) {
	user := fmt.Sprintf("[%s](%s)", e.Member.Login, e.Member.HTMLURL)
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)

	return fmt.Sprintf("%s is added to %s as collaborator",
		user,
		repo,
	), nil
}

func (g GithubListener) Delete(ctx context.Context, e *webhook.DeleteEvent) {
	d, err := g.delete(e)
	if err != nil {
		g.Log.Error("failed to parse delete event data: %+v, err: %s", e, err.Error())
		return
	}

	g.output(ctx, d)
}

func (g GithubListener) delete(e *webhook.DeleteEvent) (string, error) {
	user := fmt.Sprintf("[%s](%s)", e.Sender.Login, e.Sender.HTMLURL)
	refType := e.RefType
	ref := e.Ref
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)

	return fmt.Sprintf("%s deleted %s `%s` at %s",
		user,
		refType,
		ref,
		repo,
	), nil
}

func (g GithubListener) Create(ctx context.Context, e *webhook.CreateEvent) {
	d, err := g.create(e)
	if err != nil {
		g.Log.Error("failed to parse create tag or branch data: %+v, err: %s", e, err.Error())
		return
	}

	g.output(ctx, d)
}

func (g GithubListener) create(e *webhook.CreateEvent) (string, error) {
	user := fmt.Sprintf("[%s](%s)", e.Sender.Login, e.Sender.HTMLURL)
	refType := e.RefType
	ref := e.Ref
	repo := fmt.Sprintf("[%s](%s)", e.Repository.FullName, e.Repository.HTMLURL)

	return fmt.Sprintf("%s created %s `%s` at %s",
		user,
		refType,
		ref,
		repo,
	), nil
}

// TODO(mehmetali) limit outgoing string, should not be more than 2K char?
func (g GithubListener) output(ctx context.Context, str string) {
	gi, ok := FromGithubContext(ctx)
	if !ok {
		g.Log.Error("Could not push message: github info does not exist in the context")
		return
	}

	pr := helpers.NewPushRequest(str)
	pr.SetPayload("eventType", gi.eventType)

	if err := helpers.Push(gi.token, pr, g.IntegrationUrl); err != nil {
		g.Log.Error("Could not push message: %s", err)
	}
}

func FromGithubContext(ctx context.Context) (*GithubInfo, bool) {
	gi, ok := ctx.Value(githubInfoKey).(*GithubInfo)

	return gi, ok
}
