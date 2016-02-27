package testutil

// implements a klientctl/exec.CommandRun compatible struct for interfaces.
type FakeCommandRun struct {
	// Each time Run() is called, the args are recorded here.
	RunLog [][]string

	// Return this error when Run() is called.
	Error error

	// If true, Error is cleared when Run() is called, but the error is still returned.
	// In otherwords, Setting an error and then calling Run twice, will return the
	// error on the first run, not on the second.
	ClearErrorOnRun bool
}

func (c *FakeCommandRun) Run(bin string, args ...string) error {
	c.RunLog = append(c.RunLog, append([]string{bin}, args...))

	err := c.Error
	if c.ClearErrorOnRun {
		c.Error = nil
	}

	return err
}
