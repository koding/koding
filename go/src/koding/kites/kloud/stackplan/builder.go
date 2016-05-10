package stackplan

import (
	"errors"
	"fmt"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/stackplan/stackcred"
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

// GenericMeta represents generic meta for jCredentialDatas like userInput.
type GenericMeta map[string]interface{}

func genericMetaFunc() interface{} {
	return &GenericMeta{}
}

// MetaFuncs is a global lookup map used to initialize meta values for
// jCredentialDatas document, per provider.
var MetaFuncs = map[string]func() interface{}{
	"koding": func() interface{} { return &KodingMeta{} },
	"custom": func() interface{} { return &CustomMeta{} },
}

// metaFunc returns a meta object builder by looking up registered providers.
//
// If no builder was found it returns a builder GenericMeta.
func metaFunc(provider string) func() interface{} {
	fn, ok := MetaFuncs[provider]
	if ok {
		return fn
	}
	return genericMetaFunc
}

// BuilderOptions alternates the default behavior of the builder.
type BuilderOptions struct {
	Log       logging.Logger
	Database  Database
	CredStore stackcred.Store
}

func (opts *BuilderOptions) defaults() *BuilderOptions {
	optsCopy := *opts

	if optsCopy.Log == nil {
		optsCopy.Log = defaultLog
	}

	if optsCopy.Database == nil {
		optsCopy.Database = defaultDatabase
	}

	return &optsCopy
}

// Builder is used for building Terraform template.
type Builder struct {
	Database  *DatabaseBuilder
	Object    *object.Builder
	CredStore stackcred.Store
	Log       logging.Logger

	// Fields being built:
	Stack       *Stack
	Machines    []*models.Machine
	Koding      *Credential
	Credentials []*Credential
	Template    *Template
}

// NewBuilder gives new *Builder value.
func NewBuilder(opts *BuilderOptions) *Builder {
	opts = opts.defaults()

	b := &Builder{
		Log:       opts.Log,
		Object:    object.HCLBuilder,
		CredStore: opts.CredStore,
	}

	b.Database = &DatabaseBuilder{
		Database: opts.Database,
		Builder:  b,
	}

	return b
}

// BuildStack fetches stack details from MongoDB.
//
// When nil error is returned, the  b.Stack field is non-nil.
func (b *Builder) BuildStack(stackID string, overrideCreds map[string][]string) error {
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

	// Set or override credentials when passed in apply request.
	for k, v := range overrideCreds {
		credentials[k] = v
	}

	b.Log.Debug("Stack built: len(machines)=%d, len(credentials)=%d", len(machineIDs), len(credentials))

	b.Stack = &Stack{
		Machines:    machineIDs,
		Credentials: credentials,
		Template:    stackTemplate.Template.Content,
		Stack:       computeStack,
	}

	return nil
}

// FindMachine looks for a jMachine document in b.Machines which meta.assignedLabel
// matches the given paramter.
//
// If assignedLabel is empty, FindMachine returns nil.
// If no machine was found, FindMachine returns nil.
func (b *Builder) FindMachine(assignedLabel string) *models.Machine {
	if assignedLabel == "" {
		return nil
	}

	for _, m := range b.Machines {
		if label, ok := m.Meta["assignedLabel"].(string); ok && label == assignedLabel {
			return m
		}
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
			// we only going to select users that are allowed:
			//
			//   - team member that owns vm (sudo + owner)
			//   - team admin that owns all vms (owner + !permanent)
			//
			// A shared user is (owner + permanent).
			if (user.Sudo || !user.Permanent) && user.Owner {
				validUsers[user.Id.Hex()] = user
			} else {
				// return early, we don't tolerate nonvalid inputs to apply
				return fmt.Errorf("machine '%s' is not valid. Aborting apply", machine.ObjectId.Hex())
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

// MachineUIDs gives mapping from jMachine.meta.assignedLabel to jMachine.uid
// for each built machine.
func (b *Builder) MachineUIDs() map[string]string {
	uids := make(map[string]string)

	for _, machine := range b.Machines {
		label, ok := machine.Meta["assignedLabel"].(string)
		if !ok {
			continue
		}
		uids[label] = machine.Uid
	}
	return uids
}

// BuildCredentials fetches credential details for current b.Stack from MongoDB.
//
// When nil error is returned, the b.Koding and  b.Credentials fields are non-nil.
func (b *Builder) BuildCredentials(method, username, groupname string, identifiers []string) error {
	// fetch jaccount from username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return fmt.Errorf("fetching account %q: %s", username, err)
	}

	// fetch jGroup from group slug name
	group, err := modelhelper.GetGroup(groupname)
	if err != nil {
		return fmt.Errorf("fetching group %q: %s", groupname, err)
	}

	// fetch jUser from username
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return fmt.Errorf("fetching user %q: %s", username, err)
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
		return fmt.Errorf("fetching credentials %v: %s", identifiers, err)
	}

	credentialTitles := make(map[string]string, len(credentials))
	for _, cred := range credentials {
		credentialTitles[cred.Identifier] = cred.Title
	}

	// 3- count relationship with credential id and jaccount id as user or
	// owner. Any non valid credentials will be discarded
	validKeys := make(map[string]string, len(credentials))

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
	data := make(map[string]interface{}, len(validKeys))
	for ident, provider := range validKeys {
		data[ident] = metaFunc(provider)()
	}

	b.Log.Debug("Building credential data: %+v", data)

	if err := b.CredStore.Fetch(username, data); err != nil {
		return fmt.Errorf("error fetching credential data: %s", err)
	}

	// 5- return list of keys.
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

	for ident, provider := range validKeys {
		cred := &Credential{
			Title:      credentialTitles[ident],
			Provider:   provider,
			Identifier: ident,
			Meta:       data[ident], // TODO(rjeczalik): rename the field to Data
		}

		b.Log.Debug("%s(%s): Credential metadata: %+v", cred.Provider, cred.Identifier, cred.Meta)

		b.Credentials = append(b.Credentials, cred)
	}

	b.Log.Debug("Built credentials: %+v", b.Credentials)

	return nil
}

// BuildTemplate parsers a template from the given content and injects
// credentials.
//
// When nil error is returned, the b.Template field is non-nil.
func (b *Builder) BuildTemplate(content, contentID string) error {
	template, err := ParseTemplate(content, b.Log.New(contentID))
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
