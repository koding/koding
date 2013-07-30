package main

import (
	"code.google.com/p/goauth2/oauth"
	external "github.com/google/go-github/github"
	"log"
	"strconv"
	"time"
)

func init() {
	log.SetPrefix("Externals: ")
}

// Implements `Client` interface for Github api.
type GithubClient struct {
	Token

	// low level client that makes requests to Github.
	client *external.Client

	UserInfo strToInf
}

func NewGithubClient(token Token) Client {
	t := &oauth.Transport{
		Config: &oauth.Config{},
		Token:  &oauth.Token{AccessToken: token.Value},
	}
	client := external.NewClient(t.Client())

	return &GithubClient{token, client, strToInf{}}
}

// This client implements user info as profile info.
func (g *GithubClient) FetchUserInfo() (strToInf, error) {
	externalUser, err := g.client.Users.Get("")
	if err != nil {
		return nil, err
	}

	id := convertId(externalUser.ID)

	g.UserInfo = strToInf{
		"id":             id,
		"email":          externalUser.Email,
		"name":           externalUser.Name,
		"login":          externalUser.Login,
		"followersCount": externalUser.Followers,
		"publicRepos":    externalUser.PublicRepos,
		"location":       externalUser.Location,
		"company":        externalUser.Company,
		"origin":         "github",
	}

	return g.UserInfo, nil
}

type ResponseStruct struct {
	resp *external.RepoLanguages
	err  error
}

// This client implements tags as list of languages in user owned repos.
func (g *GithubClient) FetchTags() (strToInf, error) {
	githubRepos, err := g.client.Repositories.List("", nil)
	if err != nil {
		return nil, err
	}
	if len(githubRepos) == 0 {
		return nil, err
	}

	var done int
	totalReposCount := len(githubRepos)
	doneChh := make(chan *ResponseStruct, totalReposCount)
	timeout := time.NewTimer(time.Second * 5)

	allLangs := strToInf{}

	getRepo := func(name string) {
		langs, err := g.client.Repositories.ListLanguagesFoRepo(g.getUserLogin(), name)
		resp := ResponseStruct{langs, err}

		doneChh <- &resp
	}

	for _, gRepo := range githubRepos {
		go getRepo(gRepo.Name)
	}

	incrementAndCheckIfDone := func() bool {
		done++
		if done == totalReposCount {
			return true
		}

		return false
	}

	for {
		select {
		case resp := <-doneChh:
			if resp.err != nil {
				log.Println("ERR", err)

				if incrementAndCheckIfDone() {
					return allLangs, nil
				}
			}

			for name, lineCount := range *resp.resp {
				if count, ok := allLangs[name]; ok {
					allLangs[name] = count.(int) + lineCount
				} else {
					allLangs[name] = lineCount
				}
			}

			if incrementAndCheckIfDone() {
				return allLangs, nil
			}
		case <-timeout.C:
			failedRequests := totalReposCount - len(allLangs)
			log.Printf("%v requests timed out.", failedRequests)

			return allLangs, nil
		}
	}
}

func (g *GithubClient) FetchFriends() (strToInf, error) {
	githubUsers, err := g.client.Users.ListFollowing(g.getUserLogin())
	if err != nil {
		return nil, err
	}

	users := strToInf{}
	for _, user := range githubUsers {
		id := convertId(user.ID)
		users[id] = true
	}

	return users, nil
}

func (g *GithubClient) getUserLogin() string {
	return g.UserInfo["login"].(string)
}

func (g *GithubClient) getToken() string {
	return g.Value
}

func convertId(id int) string {
	return strconv.Itoa(id)
}
