package request

import (
	"github.com/koding/kite"
	"golang.org/x/net/context"
)

type key int

const requestKey key = 0

func FromContext(ctx context.Context) (*kite.Request, bool) {
	c, ok := ctx.Value(requestKey).(*kite.Request)
	return c, ok
}

func NewContext(ctx context.Context, req *kite.Request) context.Context {
	return context.WithValue(ctx, requestKey, req)
}
