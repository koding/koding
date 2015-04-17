package commands

import (
	"fmt"
	"io"
	"os"
	"path"

	"github.com/hashicorp/terraform/command"
	"github.com/hashicorp/terraform/terraform"
)

func (c *Context) Plan(content io.Reader) (*terraform.Plan, error) {
	cmd := command.PlanCommand{
		Meta: command.Meta{
			ContextOpts: c.TerraformContextOpts(),
			Ui:          c.ui,
		},
	}

	outputDir, err := c.createDirAndFile(content)
	if err != nil {
		return nil, err
	}

	planFilePath := path.Join(outputDir, c.id+planFileName+terraformFileExt)

	exitCode := cmd.Run([]string{
		"-no-color",          // dont write with color
		"-out", planFilePath, // save plan to a file
		outputDir,
	})

	if exitCode != 0 {
		return nil, fmt.Errorf("plan failed with code: %d", exitCode)
	}

	planFile, err := os.Open(planFilePath)
	if err != nil {
		return nil, err
	}

	return terraform.ReadPlan(planFile)
}
