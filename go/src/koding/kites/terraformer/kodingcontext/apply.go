package kodingcontext

import (
	"fmt"
	"io"
	"os"

	"github.com/hashicorp/terraform/command"
	"github.com/hashicorp/terraform/terraform"
)

// Apply applies the incoming terraform content to the remote system
func (c *KodingContext) Apply(content io.Reader, destroy bool) (*terraform.State, error) {
	cmd := &command.ApplyCommand{
		ShutdownCh: c.ShutdownChan,
		Meta: command.Meta{
			ContextOpts: c.TerraformContextOpts(),
			Ui:          c.ui,
		},
	}
	cmd.Destroy = destroy

	paths, err := c.run(cmd, content, destroy, c.populateApplyArgs)
	if err != nil {
		return nil, err
	}

	stateFile, err := os.Open(paths.statePath)
	if err != nil {
		return nil, err
	}
	defer stateFile.Close()

	return terraform.ReadState(stateFile)
}

func (c *KodingContext) populateApplyArgs(paths *paths, destroy bool) []string {
	// generate base args
	args := []string{
		"-no-color", // dont write with color
		"-state", paths.statePath,
		"-state-out", paths.statePath,
		"-input=false", // do not ask for any input
		paths.contentPath,
	}

	var vars []string
	for key, val := range c.Variables {
		// Set a variable in the Terraform configuration. This flag can be set
		// multiple times.
		vars = append(vars, "-var", fmt.Sprintf("%s=%s", key, val))
	}

	// prepend vars if there are
	args = append(vars, args...)

	// if this is a destroy operation, terraform destroy accepts force param not
	// not ask for input for destroy confirmation.
	if destroy {
		args = append([]string{"-force"}, args...)
	}

	return args

}
