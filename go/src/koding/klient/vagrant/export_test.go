package vagrant

// SetTestExec sets custom fn that executes a command specified by cmd and args
// parameters and returns the command's output.
func SetTestExec(fn func(cmd string, args ...string) ([]byte, error)) {
	testExec = fn
}

// VboxIsVagrant exports private isVagrant function for testing purpose.
func VboxIsVagrant() (bool, error) {
	return isVagrant()
}

// VboxLookupName exports private vboxLookupName method for testing purpose.
func (h *Handlers) VboxLookupName(s string) (string, error) {
	return h.vboxLookupName(s)
}

// VboxForwardedPorts exports private vboxLookupName method for testing purpose.
func (h *Handlers) VboxForwardedPorts(s string) ([]*ForwardedPort, error) {
	return h.vboxForwardedPorts(s)
}
