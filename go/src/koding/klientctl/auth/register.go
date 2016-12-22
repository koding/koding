package auth

import (
	"encoding/json"
	"fmt"
	"koding/httputil"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	endpointauth "koding/klientctl/endpoint/auth"
	"koding/klientctl/helper"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os"
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
				Name:  "username, u",
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
			cli.StringFlag{
				Name:  "company",
				Usage: "Team Company Name to register (default: team name)",
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

const (
	trueValue  = "true"
	falseValue = "false"
)

// RegisterRequest holds the registration request to Koding.
type RegisterRequest struct {
	Username        string `json:"username"`
	FirstName       string `json:"firstName"`
	LastName        string `json:"lastName"`
	Password        string `json:"password"`
	PasswordConfirm string `json:"passwordConfirm"`
	Email           string `json:"email"`
	Slug            string `json:"slug"`
	CompanyName     string `json:"companyName"`
	Newsletter      string `json:"newsletter,string"`
	AlreadyMember   string `json:"alreadyMember,string"`
	Agree           string `json:"agree"`
}

// RegisterCommand displays version information like Environment or Kite Query ID.
func RegisterCommand(c *cli.Context, log logging.Logger, _ string) int {
	rr := initRegisterRequest(c)
	r, err := checkAndAskRequiredFields(rr)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Register failed with error:", err)
		log.Error("%s", err)
		return 1
	}

	host := config.Konfig.Endpoints.Koding.Public.String()

	client := httputil.DefaultRestClient(false)

	// TODO ~mehmetali
	// handle --alreadyMember flag with various option.
	// There might be some situations that errors need to be ignored
	token, err := doRegisterRequest(r, client, host)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Register failed with error:", err)
		log.Error("%s", err)
		return 1
	}

	clientID, err := doLoginRequest(client, host, token)
	if err != nil {
		// we don't need to inform user about the error after user registered successfully
		log.Error("%s", err)
		return 1
	}

	// team cannot be empty (because of required while registering)
	// otherwise it return error while registering user
	// store groupName or slug as "team" inside the cache
	teamname := c.String("team")
	session := endpointauth.Session{
		ClientID: clientID,
		Team:     teamname,
	}
	// Set clientId and teamname into the kd.bolt
	if err := endpointauth.DefaultClient.SetSession(teamname, session); err != nil {
		log.Error("error while caching team")
		return 1
	}

	return 0
}

func initRegisterRequest(c *cli.Context) *RegisterRequest {
	return &RegisterRequest{
		Username:        c.String("username"),
		FirstName:       c.String("firstName"),
		LastName:        c.String("lastName"),
		Password:        c.String("password"),
		PasswordConfirm: c.String("passwordConfirm"),
		Email:           c.String("email"),
		Slug:            c.String("team"),
		// if company flag exists, value will be company one
		// otherwise value would be team's value
		CompanyName:   selectExistingOne(c, "company", "team"),
		Newsletter:    c.String("newsletter"),
		AlreadyMember: c.String("alreadyMember"),
		Agree:         "on",
	}
}

// selectExistingOne selects the argument that existing value
// first existing value will be chosen all the time
func selectExistingOne(c *cli.Context, args ...string) string {
	for _, arg := range args {
		if c.String(arg) != "" {
			return c.String(arg)
		}
	}

	return ""
}

func checkAndAskRequiredFields(r *RegisterRequest) (*RegisterRequest, error) {
	var err error

	if r.Username == "" {
		r.Username, err = helper.Ask("Username : ")
		if err != nil {
			return nil, err
		}
	}
	if r.FirstName == "" {
		r.FirstName, err = helper.Ask("FirstName : ")
		if err != nil {
			return nil, err
		}
	}
	if r.LastName == "" {
		r.LastName, err = helper.Ask("LastName : ")
		if err != nil {
			return nil, err
		}
	}
	if r.Password == "" {
		r.Password, err = helper.AskSecret("Password [***]: ")
		if err != nil {
			return nil, err
		}
	}
	if r.PasswordConfirm == "" {
		r.PasswordConfirm, err = helper.AskSecret("Confirm Password [***]: ")
		if err != nil {
			return nil, err
		}
		if r.PasswordConfirm != r.Password {
			return nil, fmt.Errorf("Different Password/ConfirmPassword ")
		}
	}
	if r.Email == "" {
		r.Email, err = helper.Ask("Email []: ")
		if err != nil {
			return nil, err
		}
	}
	if r.Slug == "" {
		r.Slug, err = helper.Ask("Team Name []: ")
		if err != nil {
			return nil, err
		}
	}
	if r.CompanyName == "" {
		r.CompanyName, err = helper.Ask("Company Name []: ")
		if err != nil {
			return nil, err
		}
	}
	if r.AlreadyMember == falseValue {
		r.AlreadyMember, err = helper.Ask("Are you already koding member? [%s or %s] : ", trueValue, falseValue)
		if err != nil {
			return nil, err
		}
		if r.AlreadyMember != trueValue && r.AlreadyMember != falseValue {
			return nil, fmt.Errorf("Valid input [%s or %s]", trueValue, falseValue)
		}
	}

	return r, nil
}

func doRegisterRequest(r *RegisterRequest, client *http.Client, host string) (string, error) {
	endpoint := host + "/-/teams/create"

	form := createForm(r)

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

func createForm(r *RegisterRequest) url.Values {
	form := url.Values{}
	form.Add("username", r.Username)
	form.Add("firstName", r.FirstName)
	form.Add("lastName", r.LastName)
	form.Add("password", r.Password)
	form.Add("passwordConfirm", r.PasswordConfirm)
	form.Add("email", r.Email)
	form.Add("slug", r.Slug)
	form.Add("companyName", r.CompanyName)
	form.Add("newsletter", r.Newsletter)
	form.Add("alreadyMember", r.AlreadyMember)
	form.Add("agree", "on")

	return form
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
