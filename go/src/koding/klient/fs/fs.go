package fs

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strings"

	"koding/kites/config"
)

// DefaultFS defines default filesystem.
var DefaultFS = &FS{}

// FS defines file system operations.
type FS struct {
	User *user.User // Filesystem user. If nil, config.CurrentUser will be used.
}

// Abs returns absolute representation of given path. It converts tilde prefix
// to user's home path, checks if path point to a directory, and if it exist.
func (fs *FS) Abs(path string) (string, bool, bool, error) {
	const tilde = "~" + string(os.PathSeparator)

	if strings.HasPrefix(path, tilde) {
		path = strings.Replace(path, "~", fs.user().HomeDir, 1)
	}

	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", false, false, fmt.Errorf("path %q format is invalid: %v", path, err)
	}

	switch info, err := os.Stat(absPath); {
	case os.IsNotExist(err):
		return absPath, false, false, nil
	case err != nil:
		return "", false, false, fmt.Errorf("cannot stat path: %q", absPath)
	default:
		return absPath, info.IsDir(), true, nil
	}
}

func (fs *FS) user() *user.User {
	if fs.User != nil {
		return fs.User
	}

	return config.CurrentUser.User
}
