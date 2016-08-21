package payment

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"testing"

	"github.com/koding/runner"
	"github.com/stripe/stripe-go"
)

func withConfiguration(t *testing.T, f func()) {
	const workerName = "paymentwebhook"

	r := runner.New(workerName)
	if err := r.Init(); err != nil {
		t.Fatal(err.Error())
	}
	defer r.Close()

	c := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(c.Mongo)
	defer modelhelper.Close()

	stripe.Key = c.Stripe.SecretToken
	f()
}
