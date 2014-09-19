{post} = require './requests'

stripeWebhook = (data, callback)->
  url = "/payments/stripe/webhook"
  post url, data, callback

module.exports = {
  stripeWebhook
}
