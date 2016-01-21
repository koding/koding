package vagrant

import (
	"errors"

	"golang.org/x/net/context"
)

// Info
func (m *Machine) Info(ctx context.Context) (map[string]string, error) {
	return nil, errors.New("Info not implemented")
}
