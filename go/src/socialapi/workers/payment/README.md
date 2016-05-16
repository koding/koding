# payments

To add new plan you've to do the following:

* Create plan in Stripe
  * For test env, this can be done by adding it [here](https://github.com/koding/koding/blob/master/go/src/socialapi/workers/payment/paymentplan/paymentplan.go#L42)
  * You'll have to create it manually for production
* Add migrations [here](https://github.com/koding/koding/tree/master/go/src/socialapi/db/sql/payment_definition), [here](https://github.com/koding/koding/tree/master/go/src/socialapi/db/sql/migrations) and finally [here](https://github.com/koding/koding/blob/master/config/generateRunFile.coffee#L191).
