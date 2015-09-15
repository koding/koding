package kloud

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/koding/kite"
)

type TerraformStatusRequest struct {
	StackId string `json:"stackId"`
}

type TerraformStatusResponse struct {
	StackId   string    `json:"stackId"`
	Status    string    `json:"status"`
	UpdatedAt time.Time `json:"updateAt"`
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

	computeStack, err := modelhelper.GetComputeStack(args.StackId)
	if err != nil {
		return nil, err
	}

	return &TerraformStatusResponse{
		StackId:   args.StackId,
		Status:    computeStack.Status.State,
		UpdatedAt: computeStack.Status.UpdatedAt,
	}
}
