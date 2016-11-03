package publickeys

import "golang.org/x/net/context"

type key int

const (
	publicKey key = 0

	// name of the key saved on remote provider
	DeployKeyName = "kloud-deployment"
)

type Keys struct {
	PublicKey  string
	PrivateKey string
	KeyName    string
}

func FromContext(ctx context.Context) (*Keys, bool) {
	c, ok := ctx.Value(publicKey).(*Keys)
	return c, ok
}

func NewContext(ctx context.Context, keys *Keys) context.Context {
	return context.WithValue(ctx, publicKey, keys)
}
