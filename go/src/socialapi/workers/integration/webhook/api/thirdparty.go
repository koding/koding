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
	UserRepoEndpoint = "/user/repos"
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
	Name     string `json:"name"`
	FullName string `json:"full_name"`
	Owner    struct {
		Login string `json:"login"`
	} `json:"owner"`
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

	repos, err := c.fetchRepos(githubUsername, token)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(repos)
}

func (c *Client) getUrl(path string) string {
	return fmt.Sprintf("%s%s", c.baseUrl, path)
}

func (c *Client) fetchRepos(nick, token string) ([]string, error) {
	var doRequest func(userRepos []string, page int) ([]string, error)
	doRequest = func(userRepos []string, page int) ([]string, error) {
		repoUrl := fmt.Sprintf("%s?page=%d", c.getUrl(UserRepoEndpoint), page)
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
			//if _, ok := userRepos[repo.Owner.Login]; !ok {
			//userRepos[repo.Owner.Login] = make([]string, 0)
			//}
			userRepos = append(userRepos, repo.FullName)
		}

		if len(*repos) != 0 {
			page++
			return doRequest(userRepos, page)
		}

		return userRepos, nil
	}

	return doRequest(make([]string, 0), 1)
}
