// agent is readonly wrapper around `ssh-agent` command.
package agent

import (
	"errors"
	"os/exec"
	"regexp"
	"strings"
)

var (
	ErrNotFound = errors.New("Key not found.")
	Matcher     = regexp.MustCompile("^(.*?)=(.*?); export")
)

type Client struct {
	binName   string
	binRunner func(string) (string, error)
}

func NewClient() *Client {
	return &Client{
		binName:   "ssh-agent",
		binRunner: binRunner,
	}
}

// GetAgentPid returns `SSH_AGENT_PID` value as returned by ssh-agent.
func (c *Client) GetAuthSock() (string, error) {
	return c.get("SSH_AUTH_SOCK")
}

// GetAgentPid returns `SSH_AGENT_PID` value as returned by ssh-agent.
func (c *Client) GetAgentPid() (string, error) {
	return c.get("SSH_AGENT_PID")
}

func (c *Client) get(key string) (string, error) {
	output, err := c.parse()
	if err != nil {
		return "", err
	}

	if value, ok := output[key]; ok {
		return value, nil
	}

	return "", ErrNotFound
}

func (c *Client) parse() (map[string]string, error) {
	output, err := c.binRunner(c.binName)
	if err != nil {
		return nil, err
	}

	resp := map[string]string{}

	splitOutput := strings.Split(output, "\n")
	for _, line := range splitOutput {
		matches := Matcher.FindStringSubmatch(line)
		if len(matches) > 1 {
			resp[matches[1]] = matches[2]
		}
	}

	return resp, nil
}

func binRunner(bin string) (string, error) {
	out, err := exec.Command(bin).CombinedOutput()
	if err != nil {
		return "", err
	}

	return string(out), nil
}
