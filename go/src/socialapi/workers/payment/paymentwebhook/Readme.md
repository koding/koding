# paymentwebook

This worker is responsible for receiving webhooks from vendors like stripe & paypal and acting on them. Some of the things it does is update the database with info in webhook, sends emails to user. The list of things to do for each webhook is defined here, however the logic for them is defined in their own libraries.

## Testing

go test -c
./paymentwebhook.test -c ../../../config/dev.toml
