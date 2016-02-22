package kodingcontext

import (
	"fmt"
	"io"
	"path"

	"github.com/mitchellh/cli"
)

type ArgsFunc func(paths *paths, destroy bool) []string

func (c *KodingContext) run(cmd cli.Command, content io.Reader, destroy bool, argsFunc ArgsFunc) (*paths, error) {
	// copy all contents from remote to local for operating
	if err := c.RemoteStorage.Clone(c.ContentID, c.LocalStorage); err != nil {
		return nil, err
	}

	// populate paths
	paths, err := c.paths()
	if err != nil {
		return nil, err
	}

	// override the current main file
	if err := c.LocalStorage.Write(paths.mainRelativePath, content); err != nil {
		return nil, err
	}

	go func() {
		// copy all contents from local to remote for later operating
		if err := c.LocalStorage.Clone(c.ContentID, c.RemoteStorage); err != nil {
			c.log.Error("Err while cloning local store to remote %s", err.Error())
		}
	}()

	args := argsFunc(paths, destroy)

	exitCode := cmd.Run(args)
	if exitCode != 0 {
		return nil, fmt.Errorf(
			"apply failed with code: %d, output: %s",
			exitCode,
			c.Buffer.String(),
		)
	}

	// copy all contents from local to remote for later operating
	if err := c.LocalStorage.Clone(c.ContentID, c.RemoteStorage); err != nil {
		return nil, err
	}

	return paths, nil
}

type paths struct {
	contentPath      string
	statePath        string
	planPath         string
	mainRelativePath string
}

func (c *KodingContext) paths() (*paths, error) {
	basePath, err := c.LocalStorage.BasePath()
	if err != nil {
		return nil, err
	}

	contentPath := path.Join(basePath, c.ContentID)
	mainFileRelativePath := path.Join(c.ContentID, mainFileName+terraformFileExt)
	stateFilePath := path.Join(contentPath, stateFileName+terraformStateFileExt)
	planFilePath := path.Join(contentPath, planFileName+terraformPlanFileExt)

	return &paths{
		contentPath:      contentPath,
		statePath:        stateFilePath,
		mainRelativePath: mainFileRelativePath,
		planPath:         planFilePath,
	}, nil
}
