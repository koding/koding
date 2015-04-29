package kodingcontext

import (
	"fmt"
	"io"
	"os"
	"path"

	"github.com/hashicorp/terraform/command"
	"github.com/hashicorp/terraform/terraform"
)

// Apply applies the incoming terraform content to the remote system
func (c *Context) Apply(content io.Reader, destroy bool) (*terraform.State, error) {
	cmd := command.ApplyCommand{
		ShutdownCh: c.ShutdownChan,
		Meta: command.Meta{
			ContextOpts: c.TerraformContextOpts(),
			Ui:          c.ui,
		},
	}

	// copy all contents from remote to local for operating
	if err := c.RemoteStorage.Clone(c.ContentID, c.LocalStorage); err != nil {
		return nil, err
	}

	basePath, err := c.LocalStorage.BasePath()
	if err != nil {
		return nil, err
	}

	outputDir := path.Join(basePath, c.ContentID)
	mainFileRelativePath := path.Join(c.ContentID, mainFileName+terraformFileExt)
	stateFilePath := path.Join(outputDir, stateFileName+terraformStateFileExt)

	// override the current main file
	if err := c.LocalStorage.Write(mainFileRelativePath, content); err != nil {
		return nil, err
	}

	// TODO: doesn't work because Module is not initializde and it panics.
	// Module is initialized inside cmd.Run, but then it will override
	// anything we set here. Seems the only way to pass the variable is to
	// pass with the file it self - arslan
	//
	// variables := []*config.Variable{}
	// for k, v := range c.Variables {
	//  variables = append(variables, &config.Variable{
	//      Name:    k,
	//      Default: v,
	//  })
	// }
	// cmd.ContextOpts.Module.Config().Variables = variables

	cmd.Destroy = destroy

	args := []string{
		"-no-color", // dont write with color
		"-state", stateFilePath,
		"-state-out", stateFilePath,
		"-input=false", // do not ask for any input
		outputDir,
	}

	if destroy {
		args = append([]string{"-force"}, args...)
	}

	exitCode := cmd.Run(args)

	fmt.Printf("Debug output: %+v\n", c.Buffer.String())

	if exitCode != 0 {
		return nil, fmt.Errorf(
			"apply failed with code: %d, output: %s",
			exitCode,
			c.Buffer.String(),
		)
	}

	stateFile, err := os.Open(stateFilePath)
	if err != nil {
		return nil, err
	}
	defer stateFile.Close()

	// copy all contents from local to remote for later operating
	if err := c.LocalStorage.Clone(c.ContentID, c.RemoteStorage); err != nil {
		return nil, err
	}

	return terraform.ReadState(stateFile)
}
