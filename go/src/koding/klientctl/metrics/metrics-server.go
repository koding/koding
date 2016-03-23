package metrics

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

const (
	PidFile     = "kd-metrics.pid"
	DefaultPort = "8889"
)

var ErrNoPid = errors.New("no pid file")

type Server struct {
	ConfigFolder string
	CurrentPid   int
	Port         string
	Timeout      time.Duration
	HTTPClient   *http.Client
}

func NewDefaultServer(configFolder string, pid int) *Server {
	s := &Server{
		ConfigFolder: configFolder,
		CurrentPid:   pid,
		Port:         DefaultPort,
		Timeout:      DefaultTimeout,
		HTTPClient: &http.Client{
			Timeout: DefaultTimeout,
		},
	}

	return s
}

func (s *Server) StartUnlessRunnning() error {
	if s.IsRunning() {
		return nil
	}

	c := exec.Command("kd", "metrics", "force")
	if err := c.Start(); err != nil {
		return err
	}

	return nil
}

func (s *Server) Start() error {
	if s.IsRunning() {
		return nil
	}

	p := []byte(fmt.Sprintf("%d", s.CurrentPid))
	if err := ioutil.WriteFile(s.PidPath(), p, 0644); err != nil {
		return err
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		if req.URL.Path != "/" {
			http.NotFound(w, req)
			return
		}

		path := req.FormValue("path")
		fmt.Fprintf(w, path)

		go func() {
			m := NewDefaultClient()
			if err := m.StartMountStatusTicker(); err != nil {
				fmt.Println(err)
			}
		}()
	})

	return http.ListenAndServe(":"+s.Port, mux)
}

func (s *Server) IsRunning() bool {
	resp, err := s.HTTPClient.Get(s.addr())
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	return true
}

func (s *Server) PidPath() string {
	return filepath.Join(s.ConfigFolder, PidFile)
}

func (s *Server) Pid() (string, error) {
	bites, err := ioutil.ReadFile(s.PidPath())
	if err != nil && os.IsNotExist(err) {
		return "", ErrNoPid
	}

	if err != nil {
		return "", err
	}

	return string(bites), nil
}

func (s *Server) Close() error {
	pid, err := s.Pid()
	if err != nil {
		return err
	}

	if _, err = exec.Command("kill", "-9", pid).CombinedOutput(); err != nil {
		return err
	}

	return os.Remove(s.PidPath())
}

func (s *Server) addr() string {
	return fmt.Sprintf("http://localhost:%s", s.Port)
}
