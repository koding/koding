class Environment
  DEVELOPMENT_PORT = process.env['GATEWAY_PORT'] || '3000'
  @Development = new Environment('localhost', DEVELOPMENT_PORT, false)
  @Sandbox = new Environment('sandbox.braintreegateway.com', '443', true)
  @Production = new Environment('www.braintreegateway.com', '443', true)

  constructor: (@server, @port, @ssl) ->

exports.Environment = Environment
