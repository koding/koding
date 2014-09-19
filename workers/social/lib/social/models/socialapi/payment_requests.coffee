{post, get} = require './requests'

paymentSubscribe = (data, callback)->
  requiredParams = [
    "accountId", "token", "email", "planTitle", "planInterval", "provider"
  ]

  for param in requiredParams
    if not data[param]
      return callback {message: "#{param} is required"}

  url = "/payments/subscribe"
  post url, data, callback

paymentUnsubscribe = (data, callback)->
  requiredParams = [
    "accountId", "plan", "provider"
  ]

  for param in requiredParams
    if not data[param]
      return callback {message: "#{param} is required"}

  url = "/payments/unsubscribe"
  post url, data, callback

paymentSubscriptions = (data, callback)->
  requiredParams = ['accountId']

  for param in requiredParams
    if not data[param]
      return callback {message: "#{param} is required"}

  url = "/payments/subscriptions/#{data.accountId}"
  get url, data, callback

stripeWebhook = (data, callback)->
  url = "/payments/stripe/webhook"
  post url, data, callback

module.exports = {
  paymentSubscribe
  paymentUnsubscribe
  paymentSubscriptions
  stripeWebhook
}
