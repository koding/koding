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

// Abs returns absolute representation of path. It converts tilde prefix to
// user's home path. And checks if path point to a directory.
func (fs *FS) Abs(path string) (string, bool, error) {
	const tilde = "~" + string(os.PathSeparator)

	if strings.HasPrefix(path, tilde) {
		path = strings.Replace(path, "~", fs.user().HomeDir, 1)
	}

	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", false, fmt.Errorf("path %q format is invalid: %v", path, err)
	}

	switch info, err := os.Stat(absPath); {
	case os.IsNotExist(err):
		return "", false, fmt.Errorf("file path %q does not exist", absPath)
	case err != nil:
		return "", false, fmt.Errorf("cannot stat path: %q", absPath)
	default:
		return absPath, info.IsDir(), nil
	}
}

func (fs *FS) user() *user.User {
	if fs.User != nil {
		return fs.User
	}

	return config.CurrentUser.User
}
