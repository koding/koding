package githubprovider

import (
	"errors"
	"fmt"
	"strings"

	"github.com/google/go-github/github"
	"github.com/hashicorp/terraform/helper/schema"
)

var (
	admin  string = "admin"
	member string = "member"
)

// required field are here for adding a user to the organization
func resourceGithubAddUser() *schema.Resource {
	return &schema.Resource{
		Create: resourceGithubAddUserCreate,
		Read:   resourceGithubAddUserRead,
		Update: resourceGithubAddUserCreate,
		Delete: resourceGithubAddUserDelete,

		Schema: map[string]*schema.Schema{
			"username": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			// role is the required for the membership
			// its value is member as default.
			"role": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Default:  "member",
			},

			// repos is the repos that the organization has
			"repos": &schema.Schema{
				Type:     schema.TypeList,
				Elem:     &schema.Schema{Type: schema.TypeString},
				Required: true,
			},

			// organization is the name of the organization
			"organization": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"teams": &schema.Schema{
				Type:     schema.TypeList,
				Elem:     &schema.Schema{Type: schema.TypeString},
				Required: true,
			},

			// title is the title of the SSH Key
			"title": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			// SSHKey is the public key of the user
			"SSHKey": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

// GetTeamIDs gets the teams id of the organization
func GetTeamIDs(client *github.Client, org string, teamNames []string) ([]int, error) {
	currentPage := 0

	var teamIDs []int

	for {
		options := &github.ListOptions{
			PerPage: 100,
			Page:    currentPage,
		}

		teams, resp, err := client.Organizations.ListTeams(org, options)
		if err != nil {
			return nil, err
		}

		if len(teams) == 0 {
			break
		}
		// Iterate over all teams and add current user to related team(s)
		for i, team := range teams {
			for _, teamName := range teamNames {
				if *team.Name == teamName {
					teamIDs = append(teamIDs, *teams[i].ID)
				}
			}
		}

		if currentPage == resp.LastPage {
			break
		}

		currentPage = resp.NextPage
	}

	return teamIDs, nil
}

// resourceGithubAddUserCreate adds the user to the organization & the teams
func resourceGithubAddUserCreate(d *schema.ResourceData, meta interface{}) error {
	clientOrg := meta.(*Clients).OrgClient
	client := meta.(*Clients).UserClient

	org := d.Get("organization").(string)
	user := d.Get("username").(string)
	teamNames := interfaceToStringSlice(d.Get("teams"))
	role := d.Get("role").(string)

	if err := checkScopePermissions(client, user); err != nil {
		return err
	}

	if len(teamNames) == 0 {
		return errors.New("team name is not defined")
	}

	member, _, err := client.Organizations.GetOrgMembership("", org)
	// user might be a member of organization key or not
	// with that error checking;
	// if user is a member of organization, we can change user's role as admin or member
	// if user is not a member of organization, it will give 404 error, then we need to ignore that
	// error for process (adding user into the organization etc..)
	if err != nil {
		gErr, ok := err.(*github.ErrorResponse)
		if !ok {
			return err
		}
		if gErr.Response.StatusCode != 404 {
			return err
		}
	}

	// override member role here if user is admin of organization
	if member != nil && member.Role == &admin {
		role = admin
	}

	teamIDs, err := GetTeamIDs(clientOrg, org, teamNames)

	optAddOrgMembership := &github.OrganizationAddTeamMembershipOptions{
		Role: role,
	}

	if len(teamNames) != len(teamIDs) {
		return errors.New("team name is not found")
	}

	for _, teamID := range teamIDs {
		_, _, err := clientOrg.Organizations.AddTeamMembership(teamID, user, optAddOrgMembership)
		if err != nil {
			return err
		}
	}

	active := "active"
	membership := &github.Membership{
		// state should be active to add the user into organization
		State: &active,

		// Role is the required for the membership
		Role: &role,
	}

	// EditOrgMembership edits the membership for user in specified organization.
	// if user is authenticated, we dont need to set 1.parameter as user
	_, _, err = client.Organizations.EditOrgMembership("", org, membership)
	if err != nil {
		return err
	}
	for _, repo := range interfaceToStringSlice(d.Get("repos")) {
		// Creates a fork for the authenticated user.
		_, _, err = client.Repositories.CreateFork(org, repo, nil)
		if err != nil {

			return err
		}
	}
	title := d.Get("title").(string)
	keySSH := d.Get("SSHKey").(string)

	key := &github.Key{
		Title: &title,
		Key:   &keySSH,
	}

	// CreateKey creates a public key. Requires that you are authenticated via Basic Auth,
	// or OAuth with at least `write:public_key` scope.
	//
	// If SSH key is already set up, when u try to add same SSHKEY then
	//you are gonna get 422: Validation error.
	_, _, err = client.Users.CreateKey(key)
	if err != nil && !isErr422ValidationFailed(err) {
		return err
	}
	d.SetId(user)

	return nil
}
func resourceGithubAddUserRead(d *schema.ResourceData, meta interface{}) error {
	org := d.Get("organization").(string)
	user := d.Get("username").(string)
	role := d.Get("role").(string)
	teamNames := interfaceToStringSlice(d.Get("teams"))
	repos := interfaceToStringSlice(d.Get("repos"))
	fmt.Println("org: %v, user: %v,role: %v, teamnames: %v, repos: %v",
		org,
		user,
		role,
		teamNames,
		repos,
	)

	return nil
}

// resourceGithubAddUserCreate removes the user from the organization & the teams
func resourceGithubAddUserDelete(d *schema.ResourceData, meta interface{}) error {
	// We'r not gonna use removemember for now.
	// And then we can simply return here
	return nil

	client := meta.(*Clients).OrgClient

	user := d.Get("username").(string)
	org := d.Get("organization").(string)

	// Removing a user from this list will remove them from all teams and
	// they will no longer have any access to the organization’s repositories.
	_, err := client.Organizations.RemoveMember(org, user)
	return err
}

func getKeyID(client *github.Client, user, title string) (int, error) {
	keys, _, err := client.Users.ListKeys(user, nil)
	if err != nil {
		return 0, err
	}

	for _, key := range keys {
		if *key.Title == title {
			return *key.ID, nil
		}
	}

	return 0, err
}

// interfaceToStringSlice converts the interface to slice of string
func interfaceToStringSlice(s interface{}) []string {
	slice, ok := s.([]interface{})
	if !ok {
		return nil
	}

	sslice := make([]string, len(slice))
	for i := range slice {
		sslice[i] = slice[i].(string)
	}

	return sslice
}

func checkScopePermissions(client *github.Client, username string) error {
	arr, err := getScopes(client, username)
	if err != nil {
		return err
	}

	// we created 2-dimensional array for scopes.
	scopeArray := [][]string{
		// if user enables one of this scopes, then its OK to go..
		{"write:public_key", "admin:public_key"},
		{"user"},
		{"repo", "public_repo"},
	}

	for _, scopeElement := range scopeArray {
		if !(isInArray(arr, scopeElement)) {
			scopeErr := fmt.Errorf("Could not find required scope :", scopeElement)
			return scopeErr
		}
	}

	return nil
}

func getScopes(client *github.Client, username string) ([]string, error) {
	var scopes []string
	_, resp, err := client.Users.Get(username)
	if err != nil {
		return scopes, err
	}

	list := resp.Header.Get("X-Oauth-Scopes")
	scopes = strings.Split(list, ", ")

	return scopes, nil
}

func isInArray(arr, item []string) bool {
	for _, a := range arr {
		for _, i := range item {
			if a == i {
				return true
			}
		}
	}
	return false
}

// isErr422ValidationFailed return true if error contains the string:
// '422 Validation Failed'. This error is special cased so we can ignore it on
// when it occurs during rebuilding of stack template.
func isErr422ValidationFailed(err error) bool {
	return err != nil && strings.Contains(err.Error(), "422 Validation Failed")
}
