package stackplan

import (
	"errors"
	"fmt"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/utils/object"

	"github.com/koding/logging"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// KodingMeta represents "koding_"-prefixed variables injected into Terraform
// template.
type KodingMeta struct {
	Email     string `hcl:"user_email"`
	Username  string `hcl:"user_username"`
	Nickname  string `hcl:"account_profile_nickname"`
	Firstname string `hcl:"account_profile_firstName"`
	Lastname  string `hcl:"account_profile_lastName"`
	Hash      string `hcl:"account_profile_hash"`
	Title     string `hcl:"group_title"`
	Slug      string `hcl:"group_slug"`
}

// CustomMeta represents private variables injected into Terraform template.
type CustomMeta map[string]string

// MetaFuncs is a global lookup map used to initialize meta values for
// jCredentialDatas document, per provider.
var MetaFuncs = map[string]func() interface{}{
	"koding": func() interface{} { return &KodingMeta{} },
	"custom": func() interface{} { return &CustomMeta{} },
}

// Builder is used for building Terraform template.
type Builder struct {
	Object *object.Builder
	Log    logging.Logger

	// Fields being built:
	Stack       *Stack
	Machines    []*models.Machine
	Koding      *Credential
	Credentials []*Credential
	Template    *Template
}

// NewBuilder gives new *Builder value.
func NewBuilder(log logging.Logger) *Builder {
	return &Builder{
		Log: log,
		Object: &object.Builder{
			Tag:       "hcl",
			Sep:       "_",
			Recursive: true,
		},
	}
}

// BuildStack fetches stack details from MongoDB.
//
// When nil error is returned, the  b.Stack field is non-nil.
func (b *Builder) BuildStack(stackID string) error {
	computeStack, err := modelhelper.GetComputeStack(stackID)
	if err != nil {
		return err
	}

	stackTemplate, err := modelhelper.GetStackTemplate(computeStack.BaseStackId.Hex())
	if err != nil {
		return err
	}

	machineIDs := make([]string, len(computeStack.Machines))
	for i, m := range computeStack.Machines {
		machineIDs[i] = m.Hex()
	}

	credentials := make(map[string][]string, 0)

	// first copy admin/group based credentials
	for k, v := range stackTemplate.Credentials {
		credentials[k] = v
	}

	// copy user based credentials
	for k, v := range computeStack.Credentials {
		// however don't override anything the admin already added
		if _, ok := credentials[k]; !ok {
			credentials[k] = v
		}
	}

	b.Log.Debug("Stack built: len(machines)=%d, len(credentials)=%d", len(machineIDs), len(credentials))

	b.Stack = &Stack{
		Machines:    machineIDs,
		Credentials: credentials,
		Template:    stackTemplate.Template.Content,
	}

	return nil
}

// BuildMachines fetches machines that belongs to existing b.Stack.
//
// It validates whether user is allowed to perform apply operation.
// When nil error is returned, the  b.Machines field is non-nil.
func (b *Builder) BuildMachines(ctx context.Context) error {
	ids := b.Stack.Machines

	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not passed")
	}

	mongodbIds := make([]bson.ObjectId, len(ids))
	for i, id := range ids {
		mongodbIds[i] = bson.ObjectIdHex(id)
	}

	b.Log.Debug("Building machines with IDs: %+v", ids)

	machines := make([]*models.Machine, 0)
	if err := sess.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": mongodbIds}}).All(&machines)
	}); err != nil {
		return err
	}

	b.Log.Debug("Fetched machines: %+v", machines)

	validUsers := make(map[string]models.MachineUser, 0)
	validMachines := make(map[string]*models.Machine, 0)

	for _, machine := range machines {
		// machines with empty users are supposed to allowed by default
		// (gokmen)
		if len(machine.Users) == 0 {
			validMachines[machine.ObjectId.Hex()] = machine
			continue
		}

		// for others we need to be sure they are valid
		// TODO(arslan): add custom type with custom methods for type
		// []*Machineuser
		for _, user := range machine.Users {
			// we only going to select users that are allowed
			if user.Sudo && user.Owner {
				validUsers[user.Id.Hex()] = user
			} else {
				// return early, we don't tolerate nonvalid inputs to apply
				return fmt.Errorf("machine '%s' is not valid. Aborting apply",
					machine.ObjectId.Hex())
			}
		}
	}

	allowedIds := make([]bson.ObjectId, 0)
	for _, user := range validUsers {
		allowedIds = append(allowedIds, user.Id)
	}

	b.Log.Debug("Building users with allowed IDs: %+v", allowedIds)

	users, err := modelhelper.GetUsersById(allowedIds...)
	if err != nil {
		return err
	}

	// find whether requested user is among allowed ones
	var reqUser *models.User
	for _, u := range users {
		if u.Name == req.Username {
			reqUser = u
			break
		}
	}

	if reqUser != nil {
		// now check if the requested user is inside the allowed users list
		for _, m := range machines {
			for _, user := range m.Users {
				if user.Id.Hex() == reqUser.ObjectId.Hex() {
					validMachines[m.ObjectId.Hex()] = m
					break
				}
			}
		}
	}

	if len(validMachines) == 0 {
		return fmt.Errorf("no valid machines found for the user: %s", req.Username)
	}

	for _, m := range validMachines {
		b.Machines = append(b.Machines, m)
	}

	b.Log.Debug("Machines built: %+v", machines)

	return nil
}

// BuildCredentials fetches credential details for current b.Stack from MongoDB.
//
// When nil error is returned, the b.Koding and  b.Credentials fields are non-nil.
func (b *Builder) BuildCredentials(method, username, groupname string, identifiers []string) error {
	// fetch jaccount from username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return err
	}

	// fetch jGroup from group slug name
	group, err := modelhelper.GetGroup(groupname)
	if err != nil {
		return err
	}

	// fetch jUser from username
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return err
	}

	// validate if username belongs to groupnam
	selector := modelhelper.Selector{
		"targetId": account.Id,
		"sourceId": group.Id,
		"as": bson.M{
			"$in": []string{"member"},
		},
	}

	count, err := modelhelper.RelationshipCount(selector)
	if err != nil || count == 0 {
		return fmt.Errorf("username '%s' does not belong to group '%s'", username, groupname)
	}

	// 2- fetch credential from identifiers via args
	credentials, err := modelhelper.GetCredentialsFromIdentifiers(identifiers...)
	if err != nil {
		return err
	}

	// 3- count relationship with credential id and jaccount id as user or
	// owner. Any non valid credentials will be discarded
	validKeys := make(map[string]string, 0)

	permittedTargets, ok := credPermissions[method]
	if !ok {
		return fmt.Errorf("no permission data available for method '%s'", method)
	}

	for _, cred := range credentials {
		selector := modelhelper.Selector{
			"targetId": cred.Id,
			"sourceId": bson.M{
				"$in": []bson.ObjectId{account.Id, group.Id},
			},
			"as": bson.M{"$in": permittedTargets},
		}

		count, err := modelhelper.RelationshipCount(selector)
		if err != nil || count == 0 {
			// we return for any not validated identifier key.
			return fmt.Errorf("credential with identifier '%s' is not validated: %v", cred.Identifier, err)
		}

		validKeys[cred.Identifier] = cred.Provider
	}

	// 4- fetch credentialdata with identifier
	validIdentifiers := make([]string, 0)
	for pKey := range validKeys {
		validIdentifiers = append(identifiers, pKey)
	}

	b.Log.Debug("Building valid credentials: %+v", validIdentifiers)

	credentialData, err := modelhelper.GetCredentialDatasFromIdentifiers(validIdentifiers...)
	if err != nil {
		return err
	}

	// 5- return list of keys. We only support aws for now
	b.Koding = &Credential{
		Provider: "koding",
		Meta: &KodingMeta{
			Email:     user.Email,
			Username:  user.Name,
			Nickname:  account.Profile.Nickname,
			Firstname: account.Profile.FirstName,
			Lastname:  account.Profile.LastName,
			Hash:      account.Profile.Hash,
			Title:     group.Title,
			Slug:      group.Slug,
		},
	}

	for _, c := range credentialData {
		provider, ok := validKeys[c.Identifier]
		if !ok {
			return errors.New("provider was not found for identifer: " + c.Identifier)
		}

		metaFunc, ok := MetaFuncs[provider]
		if !ok {
			return errors.New("metadata not recognized for provider: " + provider)
		}

		cred := &Credential{
			Provider:   provider,
			Identifier: c.Identifier,
			Meta:       metaFunc(),
		}

		if err := b.Object.Decode(c.Meta, cred.Meta); err != nil {
			return fmt.Errorf("malformed credential data found: %+v. Please fix it\n\terr:%s",
				c.Meta, err)
		}

		b.Log.Debug("%s(%s): Credential metadata: %+v", cred.Provider, cred.Identifier, cred.Meta)

		if validator, ok := cred.Meta.(kloud.Validator); ok {
			if err := validator.Valid(); err != nil {
				return fmt.Errorf("invalid credential %q: %s", cred.Identifier, err)
			}
		}

		b.Credentials = append(b.Credentials, cred)
	}

	b.Log.Debug("Built credentials: %+v", b.Credentials)

	return nil
}

// BuildTemplate parsers a template from the given content and injects
// credentials
//
// When nil error is returned, the b.Template field is non-nil.
func (b *Builder) BuildTemplate(content string) error {
	template, err := ParseTemplate(content)
	if err != nil {
		return err
	}

	if err := template.InjectVariables(b.Koding.Provider, b.Koding.Meta); err != nil {
		return errors.New("error injecting koding variables: " + err.Error())
	}

	for _, cred := range b.Credentials {
		if err := template.InjectVariables(cred.Provider, cred.Meta); err != nil {
			return fmt.Errorf("error injecting variables for %q: %s", cred.Provider, err)
		}
	}

	b.Template = template

	return nil
}
