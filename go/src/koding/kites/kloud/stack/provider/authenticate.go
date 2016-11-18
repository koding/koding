package provider

import (
	"strings"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/stack"

	"golang.org/x/net/context"
)

var removeNewLines = strings.NewReplacer("\n", " ", "\t", "")

func (bs *BaseStack) HandleAuthenticate(ctx context.Context) (interface{}, error) {
	arg, ok := ctx.Value(stack.AuthenticateRequestKey).(*stack.AuthenticateRequest)
	if !ok {
		arg = &stack.AuthenticateRequest{}

		if err := bs.Req.Args.One().Unmarshal(arg); err != nil {
			return nil, err
		}
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	bs.Arg = arg

	if err := bs.Builder.BuildCredentials(bs.Req.Method, bs.Req.Username, arg.GroupName, arg.Identifiers); err != nil {
		return nil, err
	}

	bs.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", bs.Builder.Koding, bs.Builder.Template)

	resp := make(stack.AuthenticateResponse)

	for _, cred := range bs.Builder.Credentials {
		res := &stack.AuthenticateResult{}
		resp[cred.Identifier] = res

		bs.Log.Debug("Checking credentials for %q (%s): %# v", cred.Provider, bs.Planner.Provider, cred.Credential)

		if cred.Provider != bs.Planner.Provider {
			continue // ignore not ours credentials
		}

		if err := bs.stack.VerifyCredential(cred); err != nil {
			res.Message = err.Error()

			if _, ok := err.(*stack.Error); ok {
				bs.Log.Warning("authenticate: %s (team=%s, user=%s, identifier=%s, provider=%s)",
					removeNewLines.Replace(err.Error()), arg.GroupName, bs.Req.Username, cred.Identifier,
					cred.Provider)
			}

			continue
		}

		if err := modelhelper.SetCredentialVerified(cred.Identifier, true); err != nil {
			res.Message = err.Error()
			continue
		}

		res.Verified = true
	}

	bs.Log.Debug("Authenticate credentials result: %+v", resp)

	return resp, nil
}
