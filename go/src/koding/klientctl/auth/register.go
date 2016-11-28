package auth

import (
	"encoding/json"
	"fmt"
	"koding/klientctl/ctlcli"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"strings"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// NewRegisterSubCommand provides the subcommand for registering
func NewRegisterSubCommand(log logging.Logger) cli.Command {
	return cli.Command{
		Name:   "register",
		Usage:  "Registers the user",
		Action: ctlcli.ExitAction(RegisterCommand, log, "register"),
		Flags: []cli.Flag{
			cli.StringFlag{
				Name:  "username",
				Usage: "Username to register",
			},
			cli.StringFlag{
				Name:  "firstName",
				Usage: "firstName to register",
			},
			cli.StringFlag{
				Name:  "lastName",
				Usage: "lastName to register",
			},
			cli.StringFlag{
				Name:  "password",
				Usage: "Username password to register",
			},
			cli.StringFlag{
				Name:  "email",
				Usage: "Email Address to register",
			},
			cli.StringFlag{
				Name:  "team",
				Usage: "Team Name to register",
			},
			cli.BoolFlag{
				Name:  "newsletter",
				Usage: "Do you want to get occasional newsletters from Koding?",
			},
			cli.BoolFlag{
				Name:  "alreadyMember",
				Usage: "Do you already registered to Koding?",
			},
		},
	}
}

// RegisterRequest holds the registration request to Koding.
type RegisterRequest struct {
	Username      string `json:"username"`
	Password      string `json:"password"`
	Email         string `json:"email"`
	Slug          string `json:"slug"`
	Newsletter    bool   `json:"newsletter,string"`
	AlreadyMember bool   `json:"alreadyMember,string"`
}

// RegisterCommand displays version information like Environment or Kite Query ID.
func RegisterCommand(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 2 {
		cli.ShowCommandHelp(c, "register")
		return 1
	}
	host := c.GlobalString("host")

	// TODO(mehmetali): make a generalized client to be used in klientctl
	client := &http.Client{}

	token, err := doRegisterRequest(c, client, host)
	if err != nil {
		log.Error(err.Error())
		return 1
	}

	clientID, err := doLoginRequest(client, host, token)
	if err != nil {
		log.Error(err.Error())
		return 1
	}

	// TODO(mehmetali): decide where to store this cookie
	fmt.Println("This is your session ID, keep it safe.", clientID)
	return 0
}

func doRegisterRequest(c *cli.Context, client *http.Client, host string) (string, error) {
	endpoint := host + "/-/teams/create"

	form := url.Values{}
	form.Add("username", c.String("username"))
	form.Add("firstName", c.String("firstName"))
	form.Add("lastName", c.String("lastName"))
	form.Add("password", c.String("password"))
	form.Add("passwordConfirm", c.String("password"))
	form.Add("email", c.String("email"))
	form.Add("slug", c.String("team"))
	form.Add("companyName", c.String("team"))
	form.Add("newsletter", c.String("newsletter"))
	form.Add("alreadyMember", c.String("alreadyMember"))
	form.Add("agree", "on")

	req, err := http.NewRequest("POST", endpoint, strings.NewReader(form.Encode()))
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("Error sending request. err: %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode > 299 {
		return "", fmt.Errorf("Invalid response code from server. code: %d", resp.StatusCode)
	}

	d := struct {
		Token string
	}{}

	if err := json.NewDecoder(resp.Body).Decode(&d); err != nil {
		return "", fmt.Errorf("Error reading response request. err: %s", err)
	}

	return d.Token, nil
}

func doLoginRequest(client *http.Client, host, token string) (string, error) {
	endpoint := host + "/-/loginwithtoken?token=" + token

	jar, err := cookiejar.New(nil)
	if err != nil {
		// cookiejar does not return any error, here for future compatibility
		panic(err)
	}
	client.Jar = jar

	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return "", fmt.Errorf("Error sending request. err: %s", err)
	}

	// store the cookie values upon redirects
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("Error sending request. err: %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode > 299 {
		return "", fmt.Errorf("Invalid response code from server. code: %d", resp.StatusCode)
	}

	urll, err := url.Parse(endpoint)
	if err != nil {
		// this should not happen since we already sent a request to it previously
		panic(err)
	}

	clientID := getClientID(jar.Cookies(urll))

	return clientID, nil
}

// getClientID gets client id from cookie, if fails, returns empty string.
func getClientID(cookies []*http.Cookie) string {
	for _, cookie := range cookies {
		if cookie.Name == "clientId" && cookie.Value != "" {
			return cookie.Value
		}
	}

	return ""
}
