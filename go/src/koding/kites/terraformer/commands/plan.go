package commands

import (
	"fmt"
	"io"
	"log"
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

	// TODO: doesn't work because Module is not initializde and it panics.
	// Module is initialized inside cmd.Run, but then it will override
	// anything we set here. Seems the only way to pass the variable is to
	// pass with the file it self - arslan
	//
	// variables := []*config.Variable{}
	// for k, v := range c.Variables {
	// 	variables = append(variables, &config.Variable{
	// 		Name:    k,
	// 		Default: v,
	// 	})
	// }
	// cmd.ContextOpts.Module.Config().Variables = variables

	exitCode := cmd.Run([]string{
		"-no-color",          // dont write with color
		"-out", planFilePath, // save plan to a file
		outputDir,
	})

	log.Printf("Debug output: %+v\n", c.Buffer.String())

	if exitCode != 0 {
		return nil, fmt.Errorf("plan failed with code: %d", exitCode)
	}

	planFile, err := os.Open(planFilePath)
	if err != nil {
		return nil, err
	}

	return terraform.ReadPlan(planFile)
}
