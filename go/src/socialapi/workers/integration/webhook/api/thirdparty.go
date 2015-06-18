package api

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
)

const (
	GithubServerURL  = "https://api.github.com"
	OrgEndpoint      = "/users/%s/orgs"
	UserRepoEndpoint = "/user/repos"
	OrgRepoEndpoint  = "/orgs/%s/repos"
)

type Client struct {
	client  *http.Client
	baseUrl string
}

type Organization struct {
	Name string `json:"login"`
}

type Repos map[string][]string

type Repo struct {
	Name string `json:"name"`
}

// FetchRepositories returns user repositories by grouping them with the organizations
func (h *Handler) FetchRepositories(u *url.URL, header http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	if !ctx.IsLoggedIn() {
		return response.NewInvalidRequest(models.ErrNotLoggedIn)
	}

	nick := ctx.Client.Account.Nick
	user, err := modelhelper.GetUser(nick)
	if err != nil {
		return response.NewBadRequest(err)
	}

	token := user.ForeignAuth.Github.Token
	githubUsername := user.ForeignAuth.Github.Username
	c := Client{
		client:  new(http.Client),
		baseUrl: GithubServerURL,
	}
	orgs, err := c.fetchOrganizations(githubUsername, token)
	if err != nil {
		return response.NewBadRequest(err)
	}

	repos, err := c.fetchUserRepos(githubUsername, token, orgs)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(repos)
}

func (c *Client) getUrl(path string) string {
	return fmt.Sprintf("%s%s", c.baseUrl, path)
}

func (c *Client) fetchOrganizations(nick, token string) ([]Organization, error) {
	endpoint := fmt.Sprintf(OrgEndpoint, nick)
	req, err := http.NewRequest("GET", c.getUrl(endpoint), nil)
	if err != nil {
		return nil, err
	}

	headerAuth := fmt.Sprintf("token %s", token)
	req.Header.Add("Authorization", headerAuth)
	resp, err := c.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, errors.New(resp.Status)
	}

	orgs := new([]Organization)
	err = json.NewDecoder(resp.Body).Decode(orgs)

	return *orgs, err
}

func (c *Client) fetchUserRepos(nick, token string, orgs []Organization) (Repos, error) {
	repos, err := c.fetchRepos(nick, token, UserRepoEndpoint)
	if err != nil {
		return nil, err
	}

	userRepos := Repos{}
	userRepos[nick] = repos

	for _, org := range orgs {
		endpoint := fmt.Sprintf(OrgRepoEndpoint, org.Name)
		repos, err := c.fetchRepos(nick, token, endpoint)
		if err != nil {
			continue
		}

		userRepos[org.Name] = repos
	}

	return userRepos, nil
}

func (c *Client) fetchRepos(nick, token, endpoint string) ([]string, error) {
	var doRequest func(repoArr []string, page int) ([]string, error)
	doRequest = func(repoArr []string, page int) ([]string, error) {
		repoUrl := fmt.Sprintf("%s?page=%d", c.getUrl(endpoint), page)
		req, err := http.NewRequest("GET", repoUrl, nil)
		if err != nil {
			return nil, err
		}

		headerAuth := fmt.Sprintf("token %s", token)
		req.Header.Add("Authorization", headerAuth)

		resp, err := c.client.Do(req)
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return nil, errors.New(resp.Status)
		}

		repos := new([]Repo)
		err = json.NewDecoder(resp.Body).Decode(repos)
		if err != nil {
			return nil, err
		}

		for _, repo := range *repos {
			repoArr = append(repoArr, repo.Name)
		}

		if len(*repos) != 0 {
			page++
			return doRequest(repoArr, page)
		}

		return repoArr, nil
	}

	return doRequest(make([]string, 0), 1)
}
