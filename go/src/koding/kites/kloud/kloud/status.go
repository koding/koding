package kloud

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"sync"
	"time"

	"github.com/koding/cache"
	"github.com/koding/kite"
)

var (
	stackCache      = cache.NewMemoryWithTTL(time.Second * 10)
	gcInitialized   = false
	gcInitializedMu sync.Mutex
)

type TerraformStatusRequest struct {
	StackId string `json:"stackId"`
}

type TerraformStatusResponse struct {
	StackId    string    `json:"stackId"`
	Status     string    `json:"status"`
	ModifiedAt time.Time `json:"modifiedAt"`
}

func (k *Kloud) Status(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformStatusRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.StackId == "" {
		return nil, errors.New("stackId is not passed")
	}

	// initialize background deleter
	gcInitializedMu.Lock()
	if !gcInitialized {
		stackCache.StartGC(time.Second * 5)
		gcInitialized = true
	}
	gcInitializedMu.Unlock()

	var resp *TerraformStatusResponse
	v, err := stackCache.Get(args.StackId)
	if err == cache.ErrNotFound {
		computeStack, err := modelhelper.GetComputeStack(args.StackId)
		if err != nil {
			return nil, err
		}

		resp = &TerraformStatusResponse{
			StackId:    args.StackId,
			Status:     computeStack.Status.State,
			ModifiedAt: computeStack.Status.ModifiedAt,
		}

		stackCache.Set(args.StackId, resp)
	} else {
		resp = v.(*TerraformStatusResponse)
	}

	return resp, nil
}
