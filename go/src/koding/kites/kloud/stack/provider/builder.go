package provider

import (
	"errors"
	"fmt"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/credential"
	"koding/kites/kloud/metadata"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/utils/object"

	"github.com/koding/logging"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// KodingMeta represents "koding_"-prefixed variables injected into Terraform
// template.
type KodingMeta struct {
	Email      string `hcl:"user_email"`
	Username   string `hcl:"user_username"`
	Nickname   string `hcl:"account_profile_nickname"`
	Firstname  string `hcl:"account_profile_firstName"`
	Lastname   string `hcl:"account_profile_lastName"`
	Hash       string `hcl:"account_profile_hash"`
	Title      string `hcl:"group_title"`
	Slug       string `hcl:"group_slug"`
	StackID    string `hcl:"stack_id"`
	TemplateID string `hcl:"template_id"`
	KlientURL  string `hcl:"klient_url"`
	ScreenURL  string `hcl:"screen_url"`
	CertURL    string `hcl:"cert_url"`
}

// CustomMeta represents private variables injected into Terraform template.
type CustomMeta map[string]string

// GenericMeta represents generic meta for jCredentialDatas like userInput.
type GenericMeta map[string]interface{}

// BuiltinSchemas is a global lookup map used to initialize meta values for
// jCredentialDatas document, per provider.
var BuiltinSchemas = map[string]*Schema{
	"koding": {
		NewCredential: func() interface{} { return &KodingMeta{} },
	},
	"custom": {
		NewCredential: func() interface{} { return &CustomMeta{} },
	},
	"generic": {
		NewCredential: func() interface{} { return &GenericMeta{} },
	},
}

// metaFunc returns a meta object builder by looking up registered providers.
//
// If no builder was found it returns a builder GenericMeta.
func schema(providerName string) *Schema {
	p, ok := providers[providerName]
	if ok && p.Schema != nil {
		return p.Schema
	}

	if schema, ok := BuiltinSchemas[providerName]; ok {
		return schema
	}

	return BuiltinSchemas["generic"]
}

// BuilderOptions alternates the default behavior of the builder.
type BuilderOptions struct {
	Log       logging.Logger
	Database  Database
	CredStore credential.Store
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
	CredStore credential.Store
	Log       logging.Logger
	Schema    map[string]*Schema

	// Fields being built:
	Team          *models.Group
	Stack         *stack.Stack
	StackTemplate *models.StackTemplate
	Machines      map[string]*models.Machine // maps label to jMachine
	Koding        *stack.Credential
	Credentials   []*stack.Credential
	Template      *Template
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

// BuildTeam fetches team details from MongoDB.
//
// When it returns with nil error, the b.Team field is
// guaranteed to be non-nil.
func (b *Builder) BuildTeam(team string) error {
	g, err := modelhelper.GetGroup(team)
	if err != nil {
		return err
	}

	b.Team = g

	return nil
}

// BuildStack fetches stack details from MongoDB.
//
// When nil error is returned, the b.Stack field is non-nil.
func (b *Builder) BuildStack(stackID string, credentials map[string][]string) error {
	var overallErr error

	computeStack, err := modelhelper.GetComputeStack(stackID)
	if err != nil {
		return models.ResError(err, "jComputeStack")
	}

	b.Stack = &stack.Stack{
		ID:          computeStack.Id,
		Stack:       computeStack,
		Machines:    make([]string, len(computeStack.Machines)),
		Credentials: make(map[string][]string),
	}

	for i, m := range b.Stack.Stack.Machines {
		b.Stack.Machines[i] = m.Hex()
	}

	baseStackID := b.Stack.Stack.BaseStackId.Hex()

	// If fetching jStackTemplate fails, it might got deleted outside.
	// Continue building stack and let the caller decide, whether missing
	// jStackTemplate is fatal or not (e.g. for apply operations it's fatal,
	// for destroy ones - not).
	if stackTemplate, err := modelhelper.GetStackTemplate(baseStackID); err == nil {
		// first copy admin/group based credentials
		for k, v := range stackTemplate.Credentials {
			b.Stack.Credentials[k] = v
		}

		b.Stack.Template = stackTemplate.Template.Content
	} else {
		overallErr = models.ResError(err, "jStackTemplate")
	}

	// copy user based credentials
	for k, v := range computeStack.Credentials {
		// however don't override anything the admin already added
		if _, ok := b.Stack.Credentials[k]; !ok {
			b.Stack.Credentials[k] = v
		}
	}

	// Set or override credentials when passed in apply request.
	for k, v := range credentials {
		if len(v) != 0 {
			b.Stack.Credentials[k] = v
		}
	}

	b.Log.Debug("Stack built: len(machines)=%d, len(credentials)=%d, overallErr=%v",
		len(b.Stack.Machines), len(b.Stack.Credentials), overallErr)

	return overallErr
}

// BuildStackTemplate fetched stack template details from MongoDB.
//
// When nil error is returned, the b.StackTemplate field is guaranteed to be non-nil.
func (b *Builder) BuildStackTemplate(templateID string) error {
	var err error
	if b.StackTemplate, err = modelhelper.GetStackTemplate(templateID); err != nil {
		return models.ResError(err, "jStackTemplate")
	}

	if b.StackTemplate.Template.Content == "" {
		return errors.New("Stack template content is empty")
	}

	return nil
}

// Authorize verifies whether user is allowed to access b.StackTemplate.
//
// Prior calling to this method it is required to build the stack
// template first.
//
// If the stack template was not built, the method is a nop.
func (b *Builder) Authorize(username string) error {
	if b.StackTemplate == nil {
		return nil // nop
	}

	return modelhelper.HasTemplateAccess(b.StackTemplate, username)
}

// FindMachine looks for a jMachine document in b.Machines which meta.assignedLabel
// matches the given parameter.
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
		return models.ResError(err, "jUser")
	}

	// find whether requested user is among allowed ones
	var reqUser *models.User
	for _, u := range users {
		if u.Name == req.Username {
			reqUser = u
			break
		}
	}

	b.Log.Debug("Found requester: %v (requester username: %s)", reqUser, req.Username)

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

	b.Machines = make(map[string]*models.Machine, len(validMachines))

	for _, m := range validMachines {
		label := m.Label
		if s, ok := m.Meta["assignedLabel"].(string); ok {
			label = s
		}

		b.Machines[label] = m
	}

	b.Log.Debug("Machines built: %+v", b.Machines)

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
//
// TODO(rjeczalik): Replace with *credential.Client
func (b *Builder) BuildCredentials(method, username, groupname string, identifiers []string) error {
	// fetch jaccount from username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return models.ResError(err, "jAccount")
	}

	// fetch jUser from username
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return models.ResError(err, "jUser")
	}

	kodingMeta := &KodingMeta{
		Email:     user.Email,
		Username:  user.Name,
		Nickname:  account.Profile.Nickname,
		Firstname: account.Profile.FirstName,
		Lastname:  account.Profile.LastName,
		Hash:      account.Profile.Hash,
		KlientURL: stack.Konfig.KlientGzURL(),
		ScreenURL: metadata.DefaultScreenURL,
		CertURL:   metadata.DefaultCertURL,
	}

	if b.StackTemplate != nil {
		kodingMeta.TemplateID = b.StackTemplate.Id.Hex()
	}

	if b.Stack != nil {
		kodingMeta.StackID = b.Stack.Stack.Id.Hex()
		kodingMeta.TemplateID = b.Stack.Stack.BaseStackId.Hex()
	}

	groupIDs := []bson.ObjectId{account.Id}

	if groupname != "" {
		// fetch jGroup from group slug name
		group, err := modelhelper.GetGroup(groupname)
		if err != nil {
			return models.ResError(err, "jGroup")
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

		kodingMeta.Title = group.Title
		kodingMeta.Slug = group.Slug

		groupIDs = append(groupIDs, group.Id)
	}

	// 2- fetch credential from identifiers via args
	credentials, err := modelhelper.GetCredentialsFromIdentifiers(identifiers...)
	if err != nil {
		return models.ResError(err, "jCredential")
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
				"$in": groupIDs,
			},
			"as": bson.M{"$in": permittedTargets},
		}

		count, err := modelhelper.RelationshipCount(selector)
		if err != nil {
			return models.ResError(err, "jRelationship")
		}
		if count == 0 {
			return fmt.Errorf("credential with identifier '%s' is not validated: %v", cred.Identifier, err)
		}

		validKeys[cred.Identifier] = cred.Provider
	}

	// 5- return list of keys.
	b.Koding = &stack.Credential{
		Provider:   "koding",
		Credential: kodingMeta,
	}

	creds := make([]*stack.Credential, 0, len(validKeys))

	for ident, provider := range validKeys {
		creds = append(creds, &stack.Credential{
			Title:      credentialTitles[ident],
			Provider:   provider,
			Identifier: ident,
		})
	}

	if err := b.FetchCredentials(username, creds...); err != nil {
		// TODO(rjeczalik): add *NotFoundError support to CredStore
		return models.ResError(err, "jCredentialData")
	}

	b.Credentials = append(b.Credentials, creds...)

	for i, cred := range b.Credentials {
		b.Log.Debug("Built credential #%d: %# v (%+v, %+v)", i, cred, cred.Credential, cred.Bootstrap)
	}

	return nil
}

// CredentialByProvider returns first encountered credential for the given provider.
func (b *Builder) CredentialByProvider(provider string) (*stack.Credential, error) {
	var cred *stack.Credential

	for _, c := range b.Credentials {
		if c.Provider == provider {
			cred = c
			break
		}
	}

	if cred == nil {
		return nil, fmt.Errorf("no credential found for %s provider", provider)
	}

	return cred, nil
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

	if err := template.InjectCredentials(append(b.Credentials, b.Koding)...); err != nil {
		return fmt.Errorf("error injecting variables: %s", err)
	}

	b.Template = template

	return nil
}

// FetchCredentials fetches credential and bootstrap data from credential store.
//
// If no credentials are provided, the method is a nop.
func (b *Builder) FetchCredentials(username string, creds ...*stack.Credential) error {
	if len(creds) == 0 {
		return nil
	}

	return b.CredStore.Fetch(username, makeCreds(true, creds...))
}

// PutCredentials updates credential and bootstrap data in credential store.
//
// If no credentials are provided, the method is a nop.
func (b *Builder) PutCredentials(username string, creds ...*stack.Credential) error {
	if len(creds) == 0 {
		return nil
	}

	return b.CredStore.Put(username, makeCreds(false, creds...))
}

// UpdateStack updates jComputeStack document using b.Stack field.
func (b *Builder) UpdateStack() error {
	return modelhelper.UpdateStack(b.Stack.ID, bson.M{
		"$set": bson.M{
			"credentials": b.Stack.Credentials,
		},
	})
}

func makeCreds(init bool, c ...*stack.Credential) map[string]interface{} {
	creds := make(map[string]interface{}, len(c))

	if init {
		// Using func-scope to defer unlocking in case user-provided
		// function panics.
		func() {
			providersMu.Lock()
			defer providersMu.Unlock()

			for _, c := range c {
				if c.Credential == nil {
					c.Credential = schema(c.Provider).newCredential()
				}
				if c.Bootstrap == nil {
					c.Bootstrap = schema(c.Provider).newBootstrap()
				}
			}
		}()
	}

	for _, c := range c {
		if c.Bootstrap == nil {
			creds[c.Identifier] = c.Credential
		} else {
			creds[c.Identifier] = object.Inline(c.Credential, c.Bootstrap)
		}
	}

	return creds
}
