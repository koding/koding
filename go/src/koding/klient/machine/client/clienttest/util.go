package clienttest

import (
	"context"
	"fmt"
	"time"
)

// WaitForContextClose waits until context is done. It times out after specified
// duration.
func WaitForContextClose(ctx context.Context, timeout time.Duration) error {
	select {
	case <-ctx.Done():
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("timed out after %s", timeout)
	}
}
