// Package klientsvc implements means to install, start
// and stop klient process as a system service.
package klientsvc

import (
	"io"
	"log"
	"os"
	"path/filepath"

	"koding/kites/config"
	"koding/klient/tunnel/tlsproxy"
	"koding/klient/uploader"

	"github.com/koding/service"
)

// DefaultService is a default klient service
// deployed within Koding.
func DefaultService() *Service {
	return &Service{
		InstallDir: "/opt/kite/klient",
		KlientBin:  os.Args[0],
		Username:   config.CurrentUser.Username,
	}
}

// Service is a klient-specific wrapper for
// a generic service.
type Service struct {
	InstallDir string
	KlientBin  string
	Username   string
}

// Install installs the service.
func (s *Service) Install() error {
	fr, err := os.Open(s.KlientBin)
	if err != nil {
		return err
	}
	defer fr.Close()

	cfg := s.config()

	if absPath, err := filepath.Abs(s.KlientBin); err != nil || absPath != cfg.Executable {
		if err := os.MkdirAll(filepath.Dir(cfg.Executable), 0755); err != nil {
			return err
		}

		fw, err := os.OpenFile(cfg.Executable, os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0755)
		if err != nil {
			return err
		}

		_, err = io.Copy(fw, fr)
		if err := nonil(err, fw.Close()); err != nil {
			return err
		}
	}

	svc, err := service.New(nopService{}, cfg)
	if err != nil {
		return err
	}

	// All the following are best-effort methods
	// to either ensure log files have proper
	// permissions so klient can upload them,
	// or sets static routes for local routing
	// webterm optimizations.
	//
	// Ignore the errors as they're not vital.
	_ = uploader.FixPerms()
	_ = tlsproxy.Init()
	_ = svc.Uninstall()

	return svc.Install()
}

// Start starts the service.
func (s *Service) Start() error {
	svc, err := service.New(nopService{}, s.config())
	if err != nil {
		return err
	}

	return svc.Start()
}

// Stop stops the service.
func (s *Service) Stop() error {
	svc, err := service.New(nopService{}, s.config())
	if err != nil {
		return err
	}

	return svc.Stop()
}

// Uninstall uninstalls the service.
func (s *Service) Uninstall() error {
	svc, err := service.New(nopService{}, s.config())
	if err != nil {
		return err
	}

	_ = svc.Stop()

	return svc.Uninstall()
}

func (s *Service) config() *service.Config {
	return &service.Config{
		Name:        "klient",
		DisplayName: "klient",
		Description: "Koding Service Connector",
		Executable:  filepath.Join(s.InstallDir, "klient"),
		Option: map[string]interface{}{
			"LogStderr":     true,
			"LogStdout":     true,
			"After":         "network.target",
			"RequiredStart": "$network",
			"LogFile":       true,
			"User":          s.Username,
			"Environment": map[string]string{
				"USERNAME": s.Username,
			},
		},
	}
}

// Install installs the DefaultService.
func Install() error {
	return DefaultService().Install()
}

// Start starts the DefaultService.
func Start() error {
	return DefaultService().Start()
}

// Stop stops the DefaultService.
func Stop() error {
	return DefaultService().Stop()
}

// Uninstall uninstalls the DefaultService.
func Uninstall() error {
	return DefaultService().Uninstall()
}

type nopService struct{}

func (nopService) Start(s service.Service) (_ error) {
	log.Printf("klientsvc: started %q service", s)
	return
}

func (nopService) Stop(s service.Service) (_ error) {
	log.Printf("klientsvc: stopped %q service", s)
	return
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
