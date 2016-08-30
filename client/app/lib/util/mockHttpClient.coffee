MockAdapter = require 'axios-mock-adapter'

module.exports = mockHttpClient = (client, endpointMocks = []) ->

  mock = new MockAdapter client

  endpointMocks.forEach ([endpoint, mock]) ->
    mock.onAny(endpoint).reply 200, mock

  return mock

