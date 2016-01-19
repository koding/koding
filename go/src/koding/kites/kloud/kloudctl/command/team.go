package command

import (
	"errors"
	"flag"
	"fmt"
	"strings"

	"koding/kites/kloud/kloud"
	"koding/kites/kloud/utils/res"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
	"golang.org/x/net/context"
)

// Team provides an implementation for "team" command.
type Team struct {
	*res.Resource
}

// NewTeam gives new Team value.
func NewTeam() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("team", "Plans/applies/describes/bootstraps team stacks")
		f.action = &Team{
			Resource: &res.Resource{
				Name:        "team",
				Description: "Plans/applies/describes/bootstraps team stacks",
				Commands: map[string]res.Command{
					"plan":      NewTeamPlan(),
					"apply":     NewTeamApply(),
					"auth":      NewTeamAuth(),
					"bootstrap": NewTeamBootstrap(),
				},
			},
		}
		return f, nil
	}
}

// Action is an entry point for "team" subcommand.
func (t *Team) Action(args []string, k *kite.Client) error {
	ctx := context.Background()
	ctx = context.WithValue(ctx, kiteKey, k)
	t.Resource.ContextFunc = func([]string) context.Context { return ctx }
	return t.Resource.Main(args)
}

/// TEAM PLAN

// TeamPlan provides an implementation for "team plan" subcommand.
type TeamPlan struct {
	Provider        string
	Team            string
	StackTemplateID string
}

// NewTeamPlan gives new TeamPlan value.
func NewTeamPlan() *TeamPlan {
	return &TeamPlan{}
}

// Valid implements the kloud.Validator interface.
func (cmd *TeamPlan) Valid() error {
	if cmd.Provider == "" {
		return errors.New("empty value for -p flag")
	}
	if cmd.StackTemplateID == "" {
		return errors.New("empty value for -tid flag")
	}
	if cmd.Team == "" {
		return errors.New("empty value for -team flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *TeamPlan) Name() string {
	return "plan"
}

// RegisterFlags sets the flags for the command - "team plan <flags>".
func (cmd *TeamPlan) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.Provider, "p", "aws", "Team provider name.")
	f.StringVar(&cmd.Team, "team", "", "Team name.")
	f.StringVar(&cmd.StackTemplateID, "tid", "", "Stack template ID.")
}

// Run executes the "team plan" subcommand.
func (cmd *TeamPlan) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}
	k := kiteFromContext(ctx)

	req := &kloud.PlanRequest{
		Provider:        cmd.Provider,
		GroupName:       cmd.Team,
		StackTemplateID: cmd.StackTemplateID,
	}

	resp, err := k.TellWithTimeout("plan", defaultTellTimeout, req)
	if err != nil {
		return err
	}

	DefaultUi.Info("plan raw response: " + string(resp.Raw))
	return nil
}

/// TEAM APPLY

// TeamApply provides an implementation for "team apply" subcommand.
type TeamApply struct {
	Provider string
	Team     string
	StackID  string
	Destroy  bool
}

// NewTeamApply gives new TeamApply value.
func NewTeamApply() *TeamApply {
	return &TeamApply{}
}

// Valid implements the kloud.Validator interface.
func (cmd *TeamApply) Valid() error {
	if cmd.Provider == "" {
		return errors.New("empty value for -p flag")
	}
	if cmd.Team == "" {
		return errors.New("empty value for -team flag")
	}
	if cmd.StackID == "" {
		return errors.New("empty value for -sid flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *TeamApply) Name() string {
	return "apply"
}

// RegisterFlags sets the flags for the command - "team apply <flags>".
func (cmd *TeamApply) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.Provider, "p", "aws", "Team provider name.")
	f.StringVar(&cmd.Team, "team", "", "Team name.")
	f.StringVar(&cmd.StackID, "sid", "", "Compute stack ID.")
	f.BoolVar(&cmd.Destroy, "del", false, "Destroy resources.")
}

// Run executes the "team apply" command.
func (cmd *TeamApply) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}
	k := kiteFromContext(ctx)

	req := &kloud.ApplyRequest{
		Provider:  cmd.Provider,
		StackID:   cmd.StackID,
		GroupName: cmd.Team,
		Destroy:   cmd.Destroy,
	}

	resp, err := k.TellWithTimeout("apply", defaultTellTimeout, req)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	DefaultUi.Info(fmt.Sprintf("%+v", result))

	return watch(k, "build", result.EventId, defaultPollInterval)
}

/// TEAM DESCRIBE

// TeamAuth provides an implementation for "team auth" subcommand.
type TeamAuth struct {
	Provider string
	Team     string
	Creds    string
}

// NewTeamAuth gives new TeamAuth value.
func NewTeamAuth() *TeamAuth {
	return &TeamAuth{}
}

// Valid implements the kloud.Validator interface.
func (cmd *TeamAuth) Valid() error {
	if cmd.Provider == "" {
		return errors.New("empty value for -p flag")
	}
	if cmd.Team == "" {
		return errors.New("empty value for -team flag")
	}
	if cmd.Creds == "" {
		return errors.New("empty value for -creds flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *TeamAuth) Name() string {
	return "auth"
}

// RegisterFlags sets the flags for the command - "team auth <flags>".
func (cmd *TeamAuth) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.Provider, "p", "aws", "Team provider name.")
	f.StringVar(&cmd.Team, "team", "", "Team name.")
	f.StringVar(&cmd.Creds, "creds", "", "Comma-separated credential identifier list.")
}

// Run executes the "team auth" subcommand.
func (cmd *TeamAuth) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}
	k := kiteFromContext(ctx)

	req := &kloud.AuthenticateRequest{
		Provider:    cmd.Provider,
		GroupName:   cmd.Team,
		Identifiers: strings.Split(cmd.Creds, ","),
	}

	resp, err := k.TellWithTimeout("authenticate", defaultTellTimeout, req)
	if err != nil {
		return err
	}

	DefaultUi.Info("authenticate raw response: " + string(resp.Raw))
	return nil
}

/// TEAM BOOTSTRAP

// TeamBootstrap provides an implementation for "team bootstrap" subcommand.
type TeamBootstrap struct {
	Provider string
	Team     string
	Creds    string
	Destroy  bool
}

// NewTeamBootstrap gives new TeamBootstrap value.
func NewTeamBootstrap() *TeamBootstrap {
	return &TeamBootstrap{}
}

// Valid implements the kloud.Validator interface.
func (cmd *TeamBootstrap) Valid() error {
	if cmd.Provider == "" {
		return errors.New("empty value for -p flag")
	}
	if cmd.Team == "" {
		return errors.New("empty value for -team flag")
	}
	if cmd.Creds == "" {
		return errors.New("empty value for -creds flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *TeamBootstrap) Name() string {
	return "bootstrap"
}

// RegisterFlags sets the flags for the command - "team bootstrap <flags>".
func (cmd *TeamBootstrap) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.Provider, "p", "aws", "Team provider name.")
	f.StringVar(&cmd.Team, "team", "", "Team name.")
	f.StringVar(&cmd.Creds, "creds", "", "Comma-separated credential identifier list.")
	f.BoolVar(&cmd.Destroy, "del", false, "Destroy resources.")
}

// Run executes the "team bootstrap" subcommand.
func (cmd *TeamBootstrap) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}
	k := kiteFromContext(ctx)

	req := &kloud.BootstrapRequest{
		Provider:    cmd.Provider,
		GroupName:   cmd.Team,
		Identifiers: strings.Split(cmd.Creds, ","),
		Destroy:     cmd.Destroy,
	}

	resp, err := k.TellWithTimeout("bootstrap", defaultTellTimeout, req)
	if err != nil {
		return err
	}

	DefaultUi.Info("bootstrap raw response: " + string(resp.Raw))
	return nil
}
