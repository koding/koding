package kontrol

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"strings"
)

type Config struct {
	// Kite specific fields
	Region      string
	Environment string
	Port        int
	Debug       bool

	// Etcd
	Machines []string

	// Mongo connection URL
	MongoURL string

	// Signing/generating tokens
	PrivateKey string
	PublicKey  string

	// SSL Support
	TLSCertFile string
	TLSKeyFile  string

	// Define storage type, such as "etcd", "postgres" etc..
	Storage string

	Postgres struct {
		Host           string `default:"localhost"`
		Port           int    `default:"5432"`
		Username       string `required:"true"`
		Password       string `required:"true"`
		DBName         string `required:"true" `
		ConnectTimeout int    `default:"20"`
	}
}

func FindPath(path string) string {
	pwd, err := os.Getwd()
	if err != nil {
		panic(err)
	}

	path = filepath.Clean(path)

	configPath := filepath.Join(pwd, path)

	// check if file with combined path is exists
	if _, err := os.Stat(configPath); !os.IsNotExist(err) {
		return configPath
	}

	// check if file is exists it self
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		return path
	}

	topLevelPath := filepath.Join(topLevel(), path)
	if _, err := os.Stat(topLevelPath); !os.IsNotExist(err) {
		return topLevelPath
	}

	panic(fmt.Errorf("couldn't find config with given parameter %s", path))
}

// TODO: implement also hg and bzr
func topLevel() string {
	out, err := exec.Command("git", "rev-parse", "--show-toplevel").CombinedOutput()
	if err != nil {
		panic(err)
	}

	return strings.TrimSpace(string(out))
}
