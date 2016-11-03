package machine

import (
	"fmt"

	"koding/kites/kloud/stack"
	"koding/klientctl/lazy"

	"github.com/koding/logging"
)

type ListOptions struct {
	Log logging.Logger
}

func List(options *ListOptions) ([]*Info, error) {
	kloud, err := lazy.Kloud()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return nil, err
	}

	req := &stack.MachineListRequest{}

	r, err := kloud.TellWithTimeout("machine.list", 10*time.Second, req)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return nil, err
	}

	res := &stack.MachineListResponse{}
	if err := r.Unmarshal(resp); err != nil {
		return nil, err
	}

	machineInfos := make([]*Info, len(res.Machines))
	for i := range res.Machines {
		fmt.Printf("machine %d: %# v\n\n", i, res.Machines[i])
	}

	return nil, nil
}
