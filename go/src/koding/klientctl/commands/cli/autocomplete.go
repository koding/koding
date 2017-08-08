package cli

import (
	"bytes"
	"crypto/md5"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"runtime"

	"github.com/spf13/cobra"
)

const autocompletionFilePath = "/usr/local/etc/bash_completion.d/kd"

type autocompleteOptions struct{}

// NewAutocompleteCommand creates a command that allows generates file
// completion for root command and all its subcommands.
func NewAutocompleteCommand(c *CLI) *cobra.Command {
	opts := &autocompleteOptions{}

	cmd := &cobra.Command{
		Use:   "autocomplete [<filepath> | - ]",
		Short: "Generate shell autocompletion script",
		RunE:  autocompleteCommand(c, opts),
	}

	// Middlewares.
	MultiCobraCmdMiddleware(
		MaxArgs(1), // Only file path is allowed.
	)(c, cmd)

	return cmd
}

func autocompleteCommand(c *CLI, opts *autocompleteOptions) CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		rootCmd := cmd.Root()
		if len(args) == 0 {
			return genBashCompletion(rootCmd, autocompletionFilePath)
		}

		if args[0] == "-" {
			return rootCmd.GenBashCompletion(c.Out())
		}

		return genBashCompletion(rootCmd, args[0])
	}
}

// GenBashCompletion generates bash completion for a given command.
func genBashCompletion(cmd *cobra.Command, filename string) error {
	if runtime.GOOS == "windows" {
		return nil
	}

	if err := os.MkdirAll(filepath.Dir(filename), 0755); err != nil {
		return err
	}

	switch _, err := os.Stat(filename); {
	case os.IsNotExist(err):
		return cmd.GenBashCompletionFile(filename)
	case err != nil:
		return err
	}

	// File already exist. Compute its MD5 sum.
	f, err := os.Open(filename)
	if err != nil {
		return err
	}
	fileMD5, err := md5sum(f)
	if err != nil {
		f.Close()
		return err
	}
	f.Close()

	// Generate a new auto completion script.
	buf := bytes.Buffer{}
	if err := cmd.GenBashCompletion(&buf); err != nil {
		return err
	}

	generatedMD5, err := md5sum(bytes.NewReader(buf.Bytes()))
	if err != nil {
		return err
	}

	if fileMD5 == generatedMD5 {
		return nil
	}

	return ioutil.WriteFile(filename, buf.Bytes(), 0644)
}

func md5sum(r io.Reader) (string, error) {
	h := md5.New()
	if _, err := io.Copy(h, r); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", h.Sum(nil)), nil
}
