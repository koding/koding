// Autocomplete handles the installation of shell autocomplete for KD implemented by
// `kd autocomplete`.
package autocomplete

import (
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"koding/klientctl/ctlcli"
	"koding/klientctl/errormessages"
	"os"
	"os/user"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/koding/logging"
)

// Options for the autocomplete install command, generally mapped 1:1 to
// CLI options for the given command.
type Options struct {
	// The shell to install autocompletions for
	Shell string

	// The directory
	FishDir string

	// The directory to install the bash autocomplete to
	BashDir string

	// Whether or not to append code that sources the bash dir, to the users bashrc
	Bashrc bool
}

// Init contains various fields required for a Command instance to be initialized.
type Init struct {
	Stdout io.Writer
	Log    logging.Logger

	// The ctlcli Helper. See the type docs for a better understanding of this.
	Helper ctlcli.Helper
}

func (i Init) CheckValid() error {
	if i.Stdout == nil {
		return errors.New("MissingArgument: Stdout")
	}

	if i.Log == nil {
		return errors.New("MissingArgument: Log")
	}

	if i.Helper == nil {
		return errors.New("MissingArgument: Helper")
	}

	return nil
}

// Command implements the klientctl.Command interface for `kd autocompletion`
type Command struct {
	Options Options
	Stdout  io.Writer
	Log     logging.Logger

	// The ctlcli Helper. See the type docs for a better understanding of this.
	Helper ctlcli.Helper
}

func NewCommand(i Init, o Options) (*Command, error) {
	if err := i.CheckValid(); err != nil {
		return nil, err
	}

	c := &Command{
		Options: o,
		Log:     i.Log,
		Stdout:  i.Stdout,
		Helper:  i.Helper,
	}

	return c, nil
}

// Help prints help to the caller.
func (c *Command) Help() {
	if c.Helper == nil {
		// Ugh, talk about a bad UX
		fmt.Fprintln(c.Stdout, "Error: Help was requested but command has no helper.")
		return
	}

	c.Helper(c.Stdout)
}

func (c *Command) Run() (int, error) {
	switch c.Options.Shell {
	case "":
		c.Help()
		return 1, nil
	case "fish":
		if err := c.InstallFish(); err != nil {
			return 1, err
		}
	case "bash":
		if err := c.InstallBash(); err != nil {
			return 1, err
		}

		if err := c.AppendToBashrc(); err != nil {
			return 1, err
		}
	default:
		fmt.Fprintln(c.Stdout, "Only bash and fish shells are supported currently.")
		// Commented out for use when we support more than just bash and fish.
		//c.Stdout.Printlnf(
		//	"The shell %s is unsupported by %s at this time.",
		//	c.Options.Shell,
		//	config.Name,
		//)
	}

	fmt.Fprintln(c.Stdout,
		`Successfully installed kd autocomplete. Note you need to restart your shell or
source your shell config file for autocomplete to work in current session.`,
	)

	return 0, nil
}

func (c *Command) InstallFish() (err error) {
	installDir := c.Options.FishDir
	if installDir == "" {
		if installDir, err = c.getDefaultFishDir(); err != nil {
			fmt.Fprintln(c.Stdout, errormessages.FishDefaultPathMissing)
			return err
		}
	}

	c.Log.Info("Installing fish autocomplete. installDir:%q", installDir)

	if err := os.MkdirAll(installDir, 0755); err != nil {
		fmt.Fprintln(c.Stdout, errormessages.FishDirFailed)
		return err
	}

	installPath := filepath.Join(installDir, fishFilename)
	err = ioutil.WriteFile(installPath, []byte(fishCompletionContents), 0644)
	if err != nil {
		fmt.Fprintln(c.Stdout, errormessages.FishWriteFailed)
		return err
	}

	return nil
}

// getSudoOrCurrentUser gets the user calling with sudo if it exists, or
// the current user.
func (c *Command) getSudoOrCurrentUser() (*user.User, error) {
	var sudoUsername string
	for _, e := range os.Environ() {
		es := strings.Split(e, "=")
		if es[0] == "SUDO_USER" && len(es) > 1 {
			sudoUsername = es[1]
		}
	}

	if sudoUsername != "" {
		return user.Lookup(sudoUsername)
	}

	return user.Current()
}

func (c *Command) chownToUser(path string, usr *user.User) error {
	uid, err := strconv.Atoi(usr.Uid)
	if err != nil {
		return err
	}

	gid, err := strconv.Atoi(usr.Gid)
	if err != nil {
		return err
	}

	if err := os.Chown(path, uid, gid); err != nil {
		return err
	}

	return nil
}

func (c *Command) getDefaultFishDir() (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	return fmt.Sprintf(fishInstallDir, usr.HomeDir), nil
}

func (c *Command) InstallBash() error {
	installDir := c.Options.FishDir
	if installDir == "" {
		installDir = bashInstallDir
	}

	err := os.MkdirAll(installDir, 0755)
	if isPermDeniedErr(err) {
		fmt.Fprintln(c.Stdout, errormessages.BashPermissionError)
		return err
	}
	if err != nil {
		fmt.Fprintln(c.Stdout, errormessages.BashDirFailed)
		return err
	}

	installPath := filepath.Join(installDir, bashFilename)
	err = ioutil.WriteFile(installPath, []byte(bashCompletionContents), 0644)
	if err != nil {
		fmt.Fprintln(c.Stdout, errormessages.BashWriteFailed)
		return err
	}

	return nil
}

func (c *Command) AppendToBashrc() error {
	// Get the user calling with sudo, or the root user directly if the user
	// is logged in with root.
	usr, err := c.getSudoOrCurrentUser()
	if err != nil {
		fmt.Fprintln(c.Stdout, errormessages.FailedToGetCurrentUser)
		return err
	}

	bashrcPath := filepath.Join(usr.HomeDir, ".bashrc")
	f, err := os.OpenFile(bashrcPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		fmt.Fprintln(c.Stdout, errormessages.FailedToAppendBashrc)
		return err
	}
	defer f.Close()

	if _, err := f.WriteString(bashSource); err != nil {
		fmt.Fprintln(c.Stdout, errormessages.FailedToAppendBashrc)
		return err
	}

	if err := c.chownToUser(bashrcPath, usr); err != nil {
		fmt.Fprintln(c.Stdout, errormessages.FailedToChown)
		return err
	}

	return nil
}

func isPermDeniedErr(err error) bool {
	if err == nil {
		return false
	}

	return strings.Contains(err.Error(), "permission denied")
}

func (c *Command) Autocomplete(args ...string) error {
	completions := []string{"bash", "fish"}
	for _, cmplt := range completions {
		fmt.Fprintln(c.Stdout, cmplt)
	}
	return nil
}
