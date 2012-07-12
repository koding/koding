sys = require "sys"
{Config} = require("./braintree/config")
{Environment} = require("./braintree/environment")
{BraintreeGateway} = require("./braintree/braintree_gateway")
errorTypes = require("./braintree/error_types")

connect = (config) ->
  new BraintreeGateway(new Config(config))

exports.connect = connect
exports.version = '0.3.0'
exports.Environment = Environment
exports.errorTypes = errorTypes
