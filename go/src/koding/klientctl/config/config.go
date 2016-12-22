// config package contains reused config variables.
package config

import (
	"fmt"
	"net/url"
	"path"
	"runtime"
	"strconv"

	"koding/kites/config"
	"koding/kites/config/configstore"
)

const (
	// Name is the user facing name for this binary. Internally we call it
	// klientctl to avoid confusion.
	Name = "kd"

	// KlientName is the user facing name for klient.
	KlientName = "KD Daemon"

	// SSHDefaultKeyDir is the default directory that stores users ssh key pairs.
	SSHDefaultKeyDir = ".ssh"

	// SSHDefaultKeyName is the default name of the ssh key pair.
	SSHDefaultKeyName = "kd-ssh-key"

	// used in combination with os-specific log paths under _linux and _darwin.
	kdLogName     = "kd.log"
	klientLogName = "klient.log"
)

var environments = map[string]string{
	"production":  "managed",
	"development": "devmanaged",
}

func kd2klient(kdEnv string) string {
	if klientEnv, ok := environments[kdEnv]; ok {
		return klientEnv
	}

	return "devmanaged"
}

var (
	// Version is the current version of klientctl. This number is used
	// by CheckUpdate to determine if current version is behind or equal to latest
	// version on S3 bucket.
	//
	// Version is overwritten during deploy via linker flag.
	Version = "0"

	// Environment is the target channel of klientctl. This value is used
	// to register with Kontrol and to install klient.
	//
	// Environment is overwritten during deploy via linker flag.
	Environment = "development"

	// KiteVersion is the version identifier used to connect to Kontrol.
	KiteVersion = "0.0." + Version

	// Used to send basic error metrics.
	//
	// Injected on build.
	SegmentKey = ""
)

var Konfig = configstore.Read(&config.Environments{
	Env:       Environment,
	KlientEnv: kd2klient(Environment),
})

func dirURL(s, env string) string {
	u, err := url.Parse(s)
	if err != nil {
		panic(err)
	}

	if env == "" {
		u.Path = path.Dir(u.Path)
	} else {
		u.Path = env
	}

	return u.String()
}

func VersionNum() int {
	version, err := strconv.ParseUint(Version, 10, 32)
	if err != nil {
		return 0
	}

	return int(version)
}

func S3Klient(version int, env string) string {
	s3dir := dirURL(Konfig.Endpoints.KlientLatest.Public.String(), kd2klient(env))

	// TODO(rjeczalik): klient uses a URL without $GOOS_$GOARCH suffix for
	// auto-updates. Remove the special case when a redirect is deployed
	// to the suffixed file.
	if runtime.GOOS == "linux" {
		return fmt.Sprintf("%[1]s/%[2]d/klient-0.1.%[2]d.gz", s3dir, version)
	}

	return fmt.Sprintf("%[1]s/%[2]d/klient-0.1.%[2]d.%[3]s_%[4]s.gz",
		s3dir, version, runtime.GOOS, runtime.GOARCH)
}

func S3Klientctl(version int, env string) string {
	return fmt.Sprintf("%s/kd-0.1.%d.%s_%s.gz", dirURL(Konfig.Endpoints.KDLatest.Public.String(), env),
		version, runtime.GOOS, runtime.GOARCH,
	)
}
