package command

import (
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/hashicorp/terraform/backend"
	"github.com/hashicorp/terraform/config/module"
	"github.com/hashicorp/terraform/terraform"
)

// ImportCommand is a cli.Command implementation that imports resources
// into the Terraform state.
type ImportCommand struct {
	Meta
}

func (c *ImportCommand) Run(args []string) int {
	// Get the pwd since its our default -config flag value
	pwd, err := os.Getwd()
	if err != nil {
		c.Ui.Error(fmt.Sprintf("Error getting pwd: %s", err))
		return 1
	}

	var configPath string
	args = c.Meta.process(args, true)

	cmdFlags := c.Meta.flagSet("import")
	cmdFlags.IntVar(&c.Meta.parallelism, "parallelism", 0, "parallelism")
	cmdFlags.StringVar(&c.Meta.statePath, "state", DefaultStateFilename, "path")
	cmdFlags.StringVar(&c.Meta.stateOutPath, "state-out", "", "path")
	cmdFlags.StringVar(&c.Meta.backupPath, "backup", "", "path")
	cmdFlags.StringVar(&configPath, "config", pwd, "path")
	cmdFlags.StringVar(&c.Meta.provider, "provider", "", "provider")
	cmdFlags.BoolVar(&c.Meta.stateLock, "lock", true, "lock state")
	cmdFlags.DurationVar(&c.Meta.stateLockTimeout, "lock-timeout", 0, "lock timeout")
	cmdFlags.Usage = func() { c.Ui.Error(c.Help()) }
	if err := cmdFlags.Parse(args); err != nil {
		return 1
	}

	args = cmdFlags.Args()
	if len(args) != 2 {
		c.Ui.Error("The import command expects two arguments.")
		cmdFlags.Usage()
		return 1
	}

	// Load the module
	var mod *module.Tree
	if configPath != "" {
		var err error
		mod, err = c.Module(configPath)
		if err != nil {
			c.Ui.Error(fmt.Sprintf("Failed to load root config module: %s", err))
			return 1
		}
	}

	// Load the backend
	b, err := c.Backend(&BackendOpts{ConfigPath: configPath})
	if err != nil {
		c.Ui.Error(fmt.Sprintf("Failed to load backend: %s", err))
		return 1
	}

	// We require a local backend
	local, ok := b.(backend.Local)
	if !ok {
		c.Ui.Error(ErrUnsupportedLocalOp)
		return 1
	}

	// Build the operation
	opReq := c.Operation()
	opReq.Module = mod

	// Get the context
	ctx, state, err := local.Context(opReq)
	if err != nil {
		c.Ui.Error(err.Error())
		return 1
	}

	// Perform the import. Note that as you can see it is possible for this
	// API to import more than one resource at once. For now, we only allow
	// one while we stabilize this feature.
	newState, err := ctx.Import(&terraform.ImportOpts{
		Targets: []*terraform.ImportTarget{
			&terraform.ImportTarget{
				Addr:     args[0],
				ID:       args[1],
				Provider: c.Meta.provider,
			},
		},
	})
	if err != nil {
		c.Ui.Error(fmt.Sprintf("Error importing: %s", err))
		return 1
	}

	// Persist the final state
	log.Printf("[INFO] Writing state output to: %s", c.Meta.StateOutPath())
	if err := state.WriteState(newState); err != nil {
		c.Ui.Error(fmt.Sprintf("Error writing state file: %s", err))
		return 1
	}
	if err := state.PersistState(); err != nil {
		c.Ui.Error(fmt.Sprintf("Error writing state file: %s", err))
		return 1
	}

	c.Ui.Output(c.Colorize().Color(fmt.Sprintf(
		"[reset][green]\n" +
			"Import success! The resources imported are shown above. These are\n" +
			"now in your Terraform state. Import does not currently generate\n" +
			"configuration, so you must do this next. If you do not create configuration\n" +
			"for the above resources, then the next `terraform plan` will mark\n" +
			"them for destruction.")))

	return 0
}

func (c *ImportCommand) Help() string {
	helpText := `
Usage: terraform import [options] ADDR ID

  Import existing infrastructure into your Terraform state.

  This will find and import the specified resource into your Terraform
  state, allowing existing infrastructure to come under Terraform
  management without having to be initially created by Terraform.

  The ADDR specified is the address to import the resource to. Please
  see the documentation online for resource addresses. The ID is a
  resource-specific ID to identify that resource being imported. Please
  reference the documentation for the resource type you're importing to
  determine the ID syntax to use. It typically matches directly to the ID
  that the provider uses.

  In the current state of Terraform import, the resource is only imported
  into your state file. Once it is imported, you must manually write
  configuration for the new resource or Terraform will mark it for destruction.
  Future versions of Terraform will expand the functionality of Terraform
  import.

  This command will not modify your infrastructure, but it will make
  network requests to inspect parts of your infrastructure relevant to
  the resource being imported.

Options:

  -backup=path        Path to backup the existing state file before
                      modifying. Defaults to the "-state-out" path with
                      ".backup" extension. Set to "-" to disable backup.

  -config=path        Path to a directory of Terraform configuration files
                      to use to configure the provider. Defaults to pwd.
                      If no config files are present, they must be provided
                      via the input prompts or env vars.

  -input=true         Ask for input for variables if not directly set.

  -lock=true          Lock the state file when locking is supported.

  -lock-timeout=0s    Duration to retry a state lock.

  -no-color           If specified, output won't contain any color.

  -provider=provider  Specific provider to use for import. This is used for
                      specifying aliases, such as "aws.eu". Defaults to the
                      normal provider prefix of the resource being imported.

  -state=path         Path to read and save state (unless state-out
                      is specified). Defaults to "terraform.tfstate".

  -state-out=path     Path to write updated state file. By default, the
                      "-state" path will be used.

  -var 'foo=bar'      Set a variable in the Terraform configuration. This
                      flag can be set multiple times. This is only useful
                      with the "-config" flag.

  -var-file=foo       Set variables in the Terraform configuration from
                      a file. If "terraform.tfvars" is present, it will be
                      automatically loaded if this flag is not specified.


`
	return strings.TrimSpace(helpText)
}

func (c *ImportCommand) Synopsis() string {
	return "Import existing infrastructure into Terraform"
}
