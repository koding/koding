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

func NewDefaultServer(configFolder string) *Server {
	s := &Server{
		ConfigFolder: configFolder,
		Port:         DefaultPort,
		Timeout:      DefaultTimeout,
		HTTPClient: &http.Client{
			Timeout: DefaultTimeout,
		},
	}

	return s
}

func (s *Server) Start(currentPid int) error {
	if s.IsRunning() {
		return nil
	}

	p := []byte(fmt.Sprintf("%d", currentPid))
	if err := ioutil.WriteFile(s.PidPath(), p, 0644); err != nil {
		return err
	}

	m := NewDefaultClient()

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		if req.URL.Path != "/" {
			http.NotFound(w, req)
			return
		}

		machine, action := req.FormValue("machine"), req.FormValue("action")
		if machine == "" || action == "" {
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte("machine|action param is empty."))
			return
		}

		if action != "start" && action != "stop" {
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte("only 'start|stop' actions are accepted"))
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte("true"))

		// start in goroutine so http request exists
		go func() {
			switch action {
			case "start":
				m.StartMountStatusTicker(machine)
			case "stop":
				m.StopMountStatusTicker(machine)
			}
		}()
	})

	return http.ListenAndServe(":"+s.Port, mux)
}

func (s *Server) IsRunning() bool {
	resp, err := s.HTTPClient.Get(s.Addr())
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

func (s *Server) Addr() string {
	return fmt.Sprintf("http://localhost:%s", s.Port)
}

func forkAndStart() error {
	c := exec.Command("kd", "metrics", "force")
	return c.Start()
}
