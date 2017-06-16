package auth

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"strings"

	"koding/httputil"
	"koding/klientctl/commands/cli"
	"koding/klientctl/config"
	endpointauth "koding/klientctl/endpoint/auth"
	"koding/klientctl/helper"

	"github.com/spf13/cobra"
)

type registerOptions struct {
	username      string
	firstName     string
	lastName      string
	password      string
	email         string
	team          string
	company       string
	newsletter    bool
	alreadyMember bool
}

// NewRegisterCommand creates a command that displays remote machines which belong
// to the user or that can be accessed by their.
func NewRegisterCommand(c *cli.CLI) *cobra.Command {
	opts := &registerOptions{}

	cmd := &cobra.Command{
		Use:   "register",
		Short: "Register the user",
		RunE:  registerCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.username, "username", "u", "", "account username")
	flags.StringVar(&opts.firstName, "firstName", "", "user first name")
	flags.StringVar(&opts.lastName, "lastName", "", "user last name")
	flags.StringVarP(&opts.password, "password", "p", "", "account password")
	flags.StringVar(&opts.email, "email", "", "email address")
	flags.StringVar(&opts.team, "team", "", "team name")
	flags.StringVar(&opts.company, "company", "", "company name, defaults to team name")
	flags.BoolVar(&opts.newsletter, "newsletter", false, "subscription to newsletters")
	flags.BoolVar(&opts.alreadyMember, "alreadyMember", false, "already registered member")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
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

func registerCommand(c *cli.CLI, opts *registerOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		rr := &RegisterRequest{
			Username:        opts.username,
			FirstName:       opts.firstName,
			LastName:        opts.lastName,
			Password:        opts.password,
			PasswordConfirm: "",
			Email:           opts.email,
			Slug:            opts.team,
			// if company flag exists, value will be company one
			// otherwise value would be team's value
			CompanyName:   selectExistingOne(opts.company, opts.team),
			Newsletter:    fmt.Sprintf("%t", opts.newsletter),
			AlreadyMember: fmt.Sprintf("%t", opts.alreadyMember),
			Agree:         "on",
		}
		r, err := checkAndAskRequiredFields(c, rr)
		if err != nil {
			c.Log().Error("Register: %s", err)
			return fmt.Errorf("register failed with error: %v", err)
		}

		host := config.Konfig.Endpoints.Koding.Public.String()
		client := httputil.Client(false)

		// TODO ~mehmetali
		// handle --alreadyMember flag with various option.
		// There might be some situations that errors need to be ignored
		token, err := doRegisterRequest(r, client, host)
		if err != nil {
			c.Log().Error("Register: %s", err)
			return fmt.Errorf("register failed with error: %v", err)
		}

		clientID, err := doLoginRequest(client, host, token)
		if err != nil {
			// we don't need to inform user about the error after user registered successfully
			c.Log().Error("Register login: %s", err)
			return nil
		}

		// team cannot be empty (because of required while registering)
		// otherwise it return error while registering user
		// store groupName or slug as "team" inside the cache
		session := &endpointauth.Session{
			ClientID: clientID,
			Team:     r.Slug,
		}

		// Set clientId and teamname into the kd.bolt
		endpointauth.Use(session)

		return nil
	}
}

// selectExistingOne selects the argument that existing value first existing
// value will be chosen all the time
func selectExistingOne(args ...string) string {
	for _, arg := range args {
		if arg != "" {
			return arg
		}
	}

	return ""
}

func checkAndAskRequiredFields(c *cli.CLI, r *RegisterRequest) (*RegisterRequest, error) {
	var err error
	if r.Username == "" {
		r.Username, err = helper.Fask(c.In(), c.Out(), "Username : ")
		if err != nil {
			return nil, err
		}
	}
	if r.FirstName == "" {
		r.FirstName, err = helper.Fask(c.In(), c.Out(), "FirstName : ")
		if err != nil {
			return nil, err
		}
	}
	if r.LastName == "" {
		r.LastName, err = helper.Fask(c.In(), c.Out(), "LastName : ")
		if err != nil {
			return nil, err
		}
	}
	if r.Password == "" {
		r.Password, err = helper.FaskSecret(c.In(), c.Out(), "Password [***]: ")
		if err != nil {
			return nil, err
		}
	}
	if r.PasswordConfirm == "" {
		r.PasswordConfirm, err = helper.FaskSecret(c.In(), c.Out(), "Confirm Password [***]: ")
		if err != nil {
			return nil, err
		}
		if r.PasswordConfirm != r.Password {
			return nil, fmt.Errorf("Different Password/ConfirmPassword ")
		}
	}
	if r.Email == "" {
		r.Email, err = helper.Fask(c.In(), c.Out(), "Email []: ")
		if err != nil {
			return nil, err
		}
	}
	if r.Slug == "" {
		r.Slug, err = helper.Fask(c.In(), c.Out(), "Team Name []: ")
		if err != nil {
			return nil, err
		}
	}
	if r.CompanyName == "" {
		r.CompanyName, err = helper.Fask(c.In(), c.Out(), "Company Name []: ")
		if err != nil {
			return nil, err
		}
	}
	if r.AlreadyMember == falseValue {
		r.AlreadyMember, err = helper.Fask(c.In(), c.Out(), "Are you already koding member? [%s or %s] : ", trueValue, falseValue)
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

	req, _ := http.NewRequest("POST", endpoint, strings.NewReader(form.Encode()))
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
