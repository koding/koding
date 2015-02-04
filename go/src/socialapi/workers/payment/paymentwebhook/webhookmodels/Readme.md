# payment#webhookmodels

This package defines various structs that represent the request from Stripe and Paypal webhooks.

The structs aren't complete, fields are added as required to avoid unncessary unmarshalling.

Stripe's webhook request depends on type of webhook, however paypal uses a generic request.
