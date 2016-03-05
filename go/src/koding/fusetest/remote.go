package fusetest

import (
	"errors"
	"fmt"
	"io/ioutil"
	"koding/klientctl/list"
	sshCmd "koding/klientctl/ssh"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"golang.org/x/crypto/ssh"
)

type Remote struct {
	SSHConn *ssh.Client

	// path to folder on remote VM
	remote string

	// path to locally mounted folder
	local string
}

func NewRemote(machine string) (*Remote, error) {
	s, err := sshCmd.NewSSHCommand(false)
	if err != nil {
		return nil, err
	}

	info, err := getMachineInfo(s, machine)
	if err != nil {
		return nil, err
	}

	if len(info.Mounts) == 0 {
		return nil, errors.New("Machine has no mount. Please mount and try again.")
	}

	conn, err := dialSSH(s.PrivateKeyPath(), info.Hostname, info.IP)
	if err != nil {
		return nil, err
	}

	return &Remote{
		SSHConn: conn,
		remote:  info.Mounts[0].RemotePath,
		local:   info.Mounts[0].LocalPath,
	}, nil
}

func (r *Remote) RunCmd(cmd string, args ...interface{}) ([]byte, error) {
	if r.SSHConn == nil {
		return nil, errors.New("No ssh connection.")
	}

	session, err := r.SSHConn.NewSession()
	if err != nil {
		return nil, err
	}

	return session.CombinedOutput(fmt.Sprintf(cmd, args...))
}

func (r *Remote) CreateDir(dir string) error {
	_, err := r.RunCmd("mkdir -p %s", r.path(dir))
	return err
}

///// test helpers

func (r *Remote) DirExists(dir string) (bool, error) {
	return r.exists("[ -d '%s' ] && echo true || echo false", r.path(dir))
}

func (r *Remote) DirPerms(dir string, mode os.FileMode) (bool, error) {
	resp, err := r.RunCmd("ls -ld %s | awk '{printf $1}'", r.path(dir))
	if err != nil {
		return false, err
	}

	fmt.Println(resp, []byte(mode.String()), string(resp), mode.String())

	if string(resp) == mode.String()+"\n" {
		return true, nil
	}

	return false, nil
}

func (r *Remote) GetEntries(dir string) ([]string, error) {
	resp, err := r.RunCmd("ls %s", r.path(dir))
	if err != nil {
		return nil, err
	}

	split := strings.Split(string(resp), "\n")

	// return without extra newline at the end
	return split[0 : len(split)-1], nil
}

func (r *Remote) RemoveDir(dir string) error {
	_, err := r.RunCmd("rm -rf %s", r.path(dir))
	return err
}

func (r *Remote) Size(path string) (int, error) {
	resp, err := r.RunCmd("ls -l %s | awk '{printf $5}'", r.path(path))
	if err != nil {
		return 0, err
	}

	return strconv.Atoi(string(resp))
}

func (r *Remote) FileExists(dir string) (bool, error) {
	return r.exists("[ -f '%s' ] && echo true || echo false", r.path(dir))
}

func (r *Remote) ReadFile(file string) (string, error) {
	resp, err := r.RunCmd("cat %s", r.path(file))
	if err != nil {
		return "", err
	}

	return string(resp), nil
}

func (r *Remote) exists(cmd string, args ...interface{}) (bool, error) {
	resp, err := r.RunCmd(cmd, args...)
	if err != nil {
		return false, err
	}

	if string(resp) == "true\n" {
		return true, nil
	}

	return false, nil
}

// path replaces local path prefix with remote path prefix.
func (r *Remote) path(p string) string {
	return filepath.Join(r.remote, strings.TrimPrefix(p, r.local))
}

///// helpers

func getMachineInfo(s *sshCmd.SSHCommand, machine string) (*list.KiteInfo, error) {
	if err := s.PrepareForSSH(machine); err != nil {
		return nil, sshCmd.ErrFailedToGetSSHKey
	}

	infos, err := s.Klient.RemoteList()
	if err != nil {
		return nil, err
	}

	info, ok := infos.FindFromName(machine)
	if !ok {
		return nil, errors.New("machine not found")
	}

	return &info, nil
}

func dialSSH(key, user, ip string) (*ssh.Client, error) {
	buf, err := ioutil.ReadFile(key)
	if err != nil {
		return nil, err
	}

	pubkey, err := ssh.ParsePrivateKey(buf)
	if err != nil {
		return nil, err
	}

	config := &ssh.ClientConfig{
		User: user,
		Auth: []ssh.AuthMethod{ssh.PublicKeys(pubkey)},
	}

	return ssh.Dial("tcp", ip+":22", config)
}
