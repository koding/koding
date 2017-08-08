package main

import (
	"os"
	"os/signal"

	"github.com/hashicorp/terraform/command"
	"github.com/mitchellh/cli"
)

// Commands is the mapping of all the available Terraform commands.
var Commands map[string]cli.CommandFactory
var PlumbingCommands map[string]struct{}

// Ui is the cli.Ui used for communicating to the outside world.
var Ui cli.Ui

const (
	ErrorPrefix  = "e:"
	OutputPrefix = "o:"
)

func init() {
	Ui = &cli.PrefixedUi{
		AskPrefix:    OutputPrefix,
		OutputPrefix: OutputPrefix,
		InfoPrefix:   OutputPrefix,
		ErrorPrefix:  ErrorPrefix,
		Ui:           &cli.BasicUi{Writer: os.Stdout},
	}

	meta := command.Meta{
		Color:       true,
		ContextOpts: &ContextOpts,
		Ui:          Ui,
	}

	// The command list is included in the terraform -help
	// output, which is in turn included in the docs at
	// website/source/docs/commands/index.html.markdown; if you
	// add, remove or reclassify commands then consider updating
	// that to match.

	PlumbingCommands = map[string]struct{}{
		"state":        struct{}{}, // includes all subcommands
		"debug":        struct{}{}, // includes all subcommands
		"force-unlock": struct{}{},
	}

	Commands = map[string]cli.CommandFactory{
		"apply": func() (cli.Command, error) {
			return &command.ApplyCommand{
				Meta:       meta,
				ShutdownCh: makeShutdownCh(),
			}, nil
		},

		"console": func() (cli.Command, error) {
			return &command.ConsoleCommand{
				Meta:       meta,
				ShutdownCh: makeShutdownCh(),
			}, nil
		},

		"destroy": func() (cli.Command, error) {
			return &command.ApplyCommand{
				Meta:       meta,
				Destroy:    true,
				ShutdownCh: makeShutdownCh(),
			}, nil
		},

		"env": func() (cli.Command, error) {
			return &command.EnvCommand{
				Meta: meta,
			}, nil
		},

		"env list": func() (cli.Command, error) {
			return &command.EnvListCommand{
				Meta: meta,
			}, nil
		},

		"env select": func() (cli.Command, error) {
			return &command.EnvSelectCommand{
				Meta: meta,
			}, nil
		},

		"env new": func() (cli.Command, error) {
			return &command.EnvNewCommand{
				Meta: meta,
			}, nil
		},

		"env delete": func() (cli.Command, error) {
			return &command.EnvDeleteCommand{
				Meta: meta,
			}, nil
		},

		"fmt": func() (cli.Command, error) {
			return &command.FmtCommand{
				Meta: meta,
			}, nil
		},

		"get": func() (cli.Command, error) {
			return &command.GetCommand{
				Meta: meta,
			}, nil
		},

		"graph": func() (cli.Command, error) {
			return &command.GraphCommand{
				Meta: meta,
			}, nil
		},

		"import": func() (cli.Command, error) {
			return &command.ImportCommand{
				Meta: meta,
			}, nil
		},

		"init": func() (cli.Command, error) {
			return &command.InitCommand{
				Meta: meta,
			}, nil
		},

		"internal-plugin": func() (cli.Command, error) {
			return &command.InternalPluginCommand{
				Meta: meta,
			}, nil
		},

		"output": func() (cli.Command, error) {
			return &command.OutputCommand{
				Meta: meta,
			}, nil
		},

		"plan": func() (cli.Command, error) {
			return &command.PlanCommand{
				Meta: meta,
			}, nil
		},

		"push": func() (cli.Command, error) {
			return &command.PushCommand{
				Meta: meta,
			}, nil
		},

		"refresh": func() (cli.Command, error) {
			return &command.RefreshCommand{
				Meta: meta,
			}, nil
		},

		"show": func() (cli.Command, error) {
			return &command.ShowCommand{
				Meta: meta,
			}, nil
		},

		"taint": func() (cli.Command, error) {
			return &command.TaintCommand{
				Meta: meta,
			}, nil
		},

		"validate": func() (cli.Command, error) {
			return &command.ValidateCommand{
				Meta: meta,
			}, nil
		},

		"version": func() (cli.Command, error) {
			return &command.VersionCommand{
				Meta:              meta,
				Revision:          GitCommit,
				Version:           Version,
				VersionPrerelease: VersionPrerelease,
				CheckFunc:         commandVersionCheck,
			}, nil
		},

		"untaint": func() (cli.Command, error) {
			return &command.UntaintCommand{
				Meta: meta,
			}, nil
		},

		//-----------------------------------------------------------
		// Plumbing
		//-----------------------------------------------------------

		"debug": func() (cli.Command, error) {
			return &command.DebugCommand{
				Meta: meta,
			}, nil
		},

		"debug json2dot": func() (cli.Command, error) {
			return &command.DebugJSON2DotCommand{
				Meta: meta,
			}, nil
		},

		"force-unlock": func() (cli.Command, error) {
			return &command.UnlockCommand{
				Meta: meta,
			}, nil
		},

		"state": func() (cli.Command, error) {
			return &command.StateCommand{}, nil
		},

		"state list": func() (cli.Command, error) {
			return &command.StateListCommand{
				Meta: meta,
			}, nil
		},

		"state rm": func() (cli.Command, error) {
			return &command.StateRmCommand{
				Meta: meta,
			}, nil
		},

		"state mv": func() (cli.Command, error) {
			return &command.StateMvCommand{
				Meta: meta,
			}, nil
		},

		"state pull": func() (cli.Command, error) {
			return &command.StatePullCommand{
				Meta: meta,
			}, nil
		},

		"state push": func() (cli.Command, error) {
			return &command.StatePushCommand{
				Meta: meta,
			}, nil
		},

		"state show": func() (cli.Command, error) {
			return &command.StateShowCommand{
				Meta: meta,
			}, nil
		},
	}
}

// makeShutdownCh creates an interrupt listener and returns a channel.
// A message will be sent on the channel for every interrupt received.
func makeShutdownCh() <-chan struct{} {
	resultCh := make(chan struct{})

	signalCh := make(chan os.Signal, 4)
	signal.Notify(signalCh, ignoreSignals...)
	signal.Notify(signalCh, forwardSignals...)
	go func() {
		for {
			<-signalCh
			resultCh <- struct{}{}
		}
	}()

	return resultCh
}
