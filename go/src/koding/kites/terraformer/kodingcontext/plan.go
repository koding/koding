package kodingcontext

import (
	"fmt"
	"io"
	"os"

	"github.com/hashicorp/terraform/command"
	"github.com/hashicorp/terraform/terraform"
)

// Plan plans the operation according to the given content
func (c *KodingContext) Plan(content io.Reader, destroy bool) (*terraform.Plan, error) {
	cmd := &command.PlanCommand{
		Meta: command.Meta{
			ContextOpts: c.TerraformContextOpts(),
			Ui:          c.ui,
		},
	}

	paths, err := c.run(cmd, content, destroy, c.populatePlanArgs)
	if err != nil {
		return nil, err
	}

	planFile, err := os.Open(paths.planPath)
	if err != nil {
		return nil, err
	}
	defer planFile.Close()

	return terraform.ReadPlan(planFile)
}

func (c *KodingContext) populatePlanArgs(paths *paths, destroy bool) []string {
	// generate base args
	args := []string{
		"-no-color",            // dont write with color
		"-out", paths.planPath, // save plan to a file
		"-state", paths.statePath,
		"-input=false", // do not ask for any input
		paths.contentPath,
	}

	// plan accordingly
	if destroy {
		args = append([]string{"-destroy"}, args...)
	}

	vars := make([]string, 0)
	for key, val := range c.Variables {
		// Set a variable in the Terraform configuration. This flag can be set
		// multiple times.
		vars = append(vars, "-var", fmt.Sprintf("%s=%s", key, val))
	}

	// prepend vars if there are
	args = append(vars, args...)

	return args

}
