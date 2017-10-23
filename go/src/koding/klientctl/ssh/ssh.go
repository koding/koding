package ssh

import (
	"errors"
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"os/user"
	"path/filepath"
	"strings"

	"github.com/koding/sshkey"
	"golang.org/x/crypto/ssh"
)

const (
	// DefaultKeyDir is the default directory that stores users SSH key pairs.
	DefaultKeyDir = ".ssh"

	// DefaultKeyName is the default name of the ssh key pair.
	DefaultKeyName = "kd-ssh-key"
)

var (
	// ErrPublicKeyNotFound indicates that provided public key does not exist.
	ErrPublicKeyNotFound = errors.New("public key not found")

	// ErrPublicKeyNotFound indicates that provided public key does not exist.
	ErrPrivateKeyNotFound = errors.New("private key not found")
)

// GetKeyPath returns default SSH keys directory for a given user. If user is
// nil, the current user will be used. It the directory does not exist, this
// function will attempt to create it.
func GetKeyPath(u *user.User) (path string, err error) {
	if u == nil {
		if u, err = user.Current(); err != nil {
			return "", err
		}
	}

	path = filepath.Join(u.HomeDir, DefaultKeyDir)
	if _, err := os.Stat(path); os.IsNotExist(err) {
		_ = os.MkdirAll(path, 0700)
	} else if err != nil {
		return "", err
	}

	return path, nil
}

// GenerateSaved generates SSH key pair and saves it in provided paths. This
// function will not replace existing keys if they already exists.
func GenerateSaved(pubPath, privPath string) (pubKey, privKey string, err error) {
	keys := map[string]string{
		"public":  pubPath,
		"private": privPath,
	}

	// Check if files exist.
	for name, keyPath := range keys {
		switch _, err := os.Stat(keyPath); {
		case err == nil:
			return "", "", fmt.Errorf("%s key file %s already exists", name, keyPath)
		case os.IsNotExist(err):
		default:
			return "", "", err
		}
	}

	// Generate keys.
	pubKey, privKey, err = sshkey.Generate()
	if err != nil {
		return "", "", err
	}

	pubKey += fmt.Sprintf(" koding-%d", rand.Int31())

	keys = map[string]string{
		pubPath:  pubKey,
		privPath: privKey,
	}

	for keyPath, content := range keys {
		if err := ioutil.WriteFile(keyPath, []byte(content), 0600); err != nil {
			return "", "", err
		}
	}

	return pubKey, privKey, nil
}

// PublicKey returns a public key stored under the given path. Public key will
// be validated before this function returns.
func PublicKey(pubPath string) (pubKey string, err error) {
	if _, err := os.Stat(pubPath); err != nil {
		return "", ErrPublicKeyNotFound
	}

	content, err := ioutil.ReadFile(pubPath)
	if err != nil {
		return "", err
	}

	// Validate key.
	if _, _, _, _, err = ssh.ParseAuthorizedKey(content); err != nil {
		return "", err
	}

	return string(content), nil
}

// PrivateKey returns a private key stored under the given path.
func PrivateKey(privPath string) (privKey interface{}, err error) {
	_, err = os.Stat(privPath)
	if os.IsNotExist(err) {
		return nil, ErrPrivateKeyNotFound
	}
	if err != nil {
		return nil, err
	}

	p, err := ioutil.ReadFile(privPath)
	if err != nil {
		return nil, err
	}

	key, err := ssh.ParseRawPrivateKey(p)
	if err != nil {
		return nil, errors.New(privPath + ": " + err.Error())
	}

	return key, nil
}

// KeyPaths generates a public and private keys paths from a given argument. If
// argument path is a directory, paths will be created from DefaultKeyName.
// If path point to either private or public key, its name will be used to
// generate corresponding path.
func KeyPaths(path string) (pubPath, privPath string, err error) {
	var isDir bool
	switch info, err := os.Stat(path); {
	case os.IsNotExist(err):
		if err := os.MkdirAll(path, 0700); err != nil {
			return "", "", err
		}
		isDir = true
	case err != nil:
		return "", "", err
	default:
		isDir = info.IsDir()
	}

	if isDir {
		privPath = filepath.Join(path, DefaultKeyName)
		pubPath = privPath + ".pub"
		return pubPath, privPath, nil
	}

	if filepath.Ext(path) == ".pub" {
		privPath = strings.TrimSuffix(path, ".pub")
		pubPath = path
	} else {
		privPath = path
		pubPath = path + ".pub"
	}

	return pubPath, privPath, nil
}
