package vagrant

import (
	"errors"

	"golang.org/x/net/context"
)

// Stop
func (m *Machine) Stop(ctx context.Context) error {
	return errors.New("Stop not implemented")
}
