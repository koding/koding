# paymentwebook

This worker is responsible for receiving webhooks from vendors like stripe & paypal and acting on them. Some of the things it does is update the database with info in webhook, sends emails to user. The list of things to do for each webhook is defined here, however the logic for them is defined in their own libraries.

I started with idea of creating webhook to actions mapping, but due to Go's static nature, differences in webhook requests and minor changes in handling the webhook, I decided to not go that path and be more explicit. The underlying actions are abstracted out so there's little duplication. It's little more code, however it's lot more readable. Adding new webhook handlers is simple and so is adding new vendors.

One thing to note, paypal webhooks are directed via node webserver since paypal sends in `application/x-www-form-urlencoded` and go doesn't support unmarshalling it into a struct like it does for json. Marshalling that into json and then unmarshalling oddly returns arrays for ALL values. The webhooks were originally redirected via node webserver for different reasons, so I decided to keep it there.

## Update March 23, 2015

We've moved to using SegmentIO + Iterable to send emails. This worker no longer calls sendgrid api; it sends message to `emailSender` which then sends events to Iterable.

## Testing

go test -c
./paymentwebhook.test -c ../../../config/dev.toml
