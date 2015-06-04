# tokenizer

tokenizer is a worker responsible for generating and verify auth tokens. Currently it generates only `jwt` token to be used in emails for single sign on.

## Tests

go test

## Notes

Be sure to read about `https://auth0.com/blog/2015/03/31/critical-vulnerabilities-in-json-web-token-libraries/` if you're going to make change to the way tokens are generated.
