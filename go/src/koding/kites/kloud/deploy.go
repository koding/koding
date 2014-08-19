package main

import (
	"errors"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kloud"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/sshutil"
	"github.com/koding/logging"

	kiteprotocol "github.com/koding/kite/protocol"
	"github.com/nu7hatch/gouuid"
	"github.com/pkg/sftp"
)

type KodingDeploy struct {
	Kite *kite.Kite
	Log  logging.Logger

	// needed for signing/generating kite tokens
	KontrolPublicKey  string
	KontrolPrivateKey string
	KontrolURL        string

	Bucket *Bucket
}

const (
	// Port to bind apache to by default
	apachePort = 80
)

func (k *KodingDeploy) ServeKite(r *kite.Request) (interface{}, error) {
	data, err := r.Context.Get("buildArtifact")
	if err != nil {
		return nil, errors.New("koding-deploy: build artifact is not available")
	}

	artifact, ok := data.(*protocol.Artifact)
	if !ok {
		return nil, fmt.Errorf("koding-deploy: build artifact is malformed: %+v", data)
	}

	username := artifact.Username
	ipAddress := artifact.IpAddress
	// hostname := artifact.InstanceName
	privateKey := artifact.SSHPrivateKey
	sshusername := artifact.SSHUsername

	log := func(msg string) {
		k.Log.Info("%s ==> %s", username, msg)
	}

	sshAddress := ipAddress + ":22"
	sshConfig, err := sshutil.SshConfig(sshusername, privateKey)
	if err != nil {
		return nil, err
	}

	log("Connecting to SSH: " + sshAddress)
	client, err := sshutil.ConnectSSH(sshAddress, sshConfig)
	if err != nil {
		return nil, err
	}
	defer client.Close()

	sftp, err := sftp.NewClient(client.Client)
	if err != nil {
		return nil, err
	}

	log("Creating a kite.key directory")
	err = sftp.Mkdir("/etc/kite")
	if err != nil {
		return nil, err
	}

	tknID, err := uuid.NewV4()
	if err != nil {
		return nil, kloud.NewError(kloud.ErrSignGenerateToken)
	}

	log("Creating user account")
	out, err := client.StartCommand(createUserCommand(username))
	if err != nil {
		fmt.Println("out", out)
		return nil, err
	}

	log("Creating a key with kontrolURL: " + k.KontrolURL)
	kiteKey, err := k.createKey(username, tknID.String())
	if err != nil {
		return nil, err
	}

	remoteFile, err := sftp.Create("/etc/kite/kite.key")
	if err != nil {
		return nil, err
	}

	log("Copying kite.key to remote machine")
	_, err = remoteFile.Write([]byte(kiteKey))
	if err != nil {
		return nil, err
	}

	log("Fetching latest klient.deb binary")
	latestDeb, err := k.Bucket.Latest()
	if err != nil {
		return nil, err
	}

	// splitted => [klient 0.0.1 environment arch.deb]
	splitted := strings.Split(latestDeb, "_")
	if len(splitted) != 4 {
		// should be a valid deb
		return nil, fmt.Errorf("invalid deb file: %v", latestDeb)
	}

	// signedURL allows us to have public access for a limited time frame
	signedUrl := k.Bucket.SignedURL(latestDeb, time.Now().Add(time.Minute*3))

	log("Downloading '" + filepath.Base(latestDeb) + "' to /tmp inside the machine")
	out, err = client.StartCommand(fmt.Sprintf("wget -O /tmp/klient-latest.deb '%s'", signedUrl))
	if err != nil {
		fmt.Println("out", out)
		return nil, err
	}

	log("Installing klient deb on the machine")
	out, err = client.StartCommand("dpkg -i /tmp/klient-latest.deb")
	if err != nil {
		fmt.Println("out", out)
		return nil, err
	}

	log("Removing leftover klient deb from the machine")
	out, err = client.StartCommand("rm -f /tmp/klient-latest.deb")
	if err != nil {
		fmt.Println("out", out)
		return nil, err
	}

	log("Patching klient.conf")
	out, err = client.StartCommand(patchConfCommand(username))
	if err != nil {
		fmt.Println("out", out)
		return nil, err
	}

	log("Restarting klient with kite.key")
	out, err = client.StartCommand("service klient restart")
	if err != nil {
		return nil, err
	}

	log("Making user's default directories")
	out, err = client.StartCommand(makeDirectoriesCommand(username))
	if err != nil {
		return nil, err
	}

	log("Tweaking apache config")
	if err := changeApacheConf(client, apachePort); err != nil {
		return nil, err
	}

	log("Setting up users' Web/ directory to be served by apache")
	out, err = client.StartCommand(webSetupCommand(username))
	if err != nil {
		fmt.Println("out", out)
		return nil, err
	}

	log("Restarting apache2 with new config")
	out, err = client.StartCommand("service apache2 restart")
	if err != nil {
		return nil, err
	}

	query := kiteprotocol.Kite{ID: tknID.String()}

	// TODO: enable this later in production, currently it's just slowing down
	// local development.
	k.Log.Info("Connecting to remote Klient instance")
	klient, err := k.Klient(query.String())
	if err != nil {
		k.Log.Warning("Connecting to remote Klient instance err: %s", err)
	} else {
		k.Log.Info("Sending a ping message")
		if err := klient.Ping(); err != nil {
			k.Log.Warning("Sending a ping message err:", err)
		}
	}

	artifact.KiteQuery = query.String()
	return artifact, nil
}

// Build the command used to create the user
func createUserCommand(username string) string {
	// 1. Create user
	// 2. Remove user's password
	// 3. Add user to sudo group
	// 4. Add user to sudoers
	return fmt.Sprintf(`
adduser --shell /bin/bash --gecos 'koding user' --disabled-password --home /home/%[1]s %[1]s && \
passwd -d %[1]s && \
gpasswd -a %[1]s sudo  && \
echo '%[1]s    ALL = NOPASSWD: ALL' > /etc/sudoers.d/%[1]s
 `, username)

}

// webSetupCommand generates a bash command configuring apache for a given user
func webSetupCommand(username string) string {
	return fmt.Sprintf(`
rm -rf /var/www; \
ln -s /home/%s/Web /var/www
`, username)
}

// Build the klient.conf patching command
func patchConfCommand(username string) string {
	return fmt.Sprintf(
		// "sudo -E", preserves the environment variables when forking
		// so KITE_HOME set by the upstart script is preserved etc ...
		"sed -i 's/\\.\\/klient/sudo -E -u %s \\.\\/klient/g' /etc/init/klient.conf",
		username,
	)
}

// makeDirectoriesCommand ensures that all the user's default folders exist
// and creates them if they don't
func makeDirectoriesCommand(username string) string {
	return fmt.Sprintf(`
sudo -u %[1]s mkdir -p /home/%[1]s/Applications && \
sudo -u %[1]s mkdir -p /home/%[1]s/Backup && \
sudo -u %[1]s mkdir -p /home/%[1]s/Documents && \
sudo -u %[1]s mkdir -p /home/%[1]s/Web
`, username)
}

// changeHostname is used to change the remote machines hostname by modifying
// their /etc/host and /etc/hostname files.
func changeHostname(client *sshutil.SSHClient, hostname string) error {
	hostFile, err := client.Create("/etc/hosts")
	if err != nil {
		return err
	}

	if err := hostsTemplate.Execute(hostFile, hostname); err != nil {
		return err
	}

	hostnameFile, err := client.Create("/etc/hostname")
	if err != nil {
		return err
	}

	_, err = hostnameFile.Write([]byte(hostname))
	if err != nil {
		return err
	}

	out, err := client.StartCommand(fmt.Sprintf("hostname %s", hostname))
	if err != nil {
		fmt.Printf("out %+v\n", out)
		return err
	}

	return nil
}

// changeApacheConf is used to change apache's default configuration
// so that it listens on the port of our choice and serves /var/www
// rather than /var/www/html (/var/www is symlinked to user's ~/Web)
func changeApacheConf(client *sshutil.SSHClient, port int) error {
	apacheFile, err := client.Create("/etc/apache2/sites-available/000-default.conf")
	if err != nil {
		return err
	}

	// Write conf file
	if err := apacheTemplate.Execute(apacheFile, port); err != nil {
		return err
	}

	apachePortsFile, err := client.Create("/etc/apache2/ports.conf")
	if err != nil {
		return err
	}

	// Write /etc/apache2/ports.conf file
	return apachePortsTemplate.Execute(apachePortsFile, port)
}
