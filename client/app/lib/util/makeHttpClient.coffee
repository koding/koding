{ assign } = require 'lodash'
axios = require 'axios'

# makeHttpClient: accepts axios#requestconfig with some defaults. It also
# patches the returned axios instance's request methods to prevent a weird bug
# from it removing `Content-Type` headers.
module.exports = makeHttpClient = (params = {}) ->

  defaults =
    headers:
      'Content-Type': 'application/json;charset=utf-8'
    data: {}


  client = axios.create(
    assign {}, defaults, params
  )

  return patchClient client

# patchClient: accepts an axios client and patches its request methods with
# default arguments to prevent it removing content-type header.
patchClient = (client) ->
  ['post', 'put', 'patch'].forEach (method) ->
    client[method] = (withArgs client[method]).bind(client)

  return client

# withArgs: given a request method it will return a new function that mimics
# the axios#request methods but injects default parameter for data and config.
withArgs = (fn) -> (url, data = {}, config = {}) -> fn(url, data, config)


makeHttpClient.helpers =

  # pickData: a decorator function to take an axios handler and returns a new
  # handler that will automatically resolve `response.data`.
  #
  # Without pickData resulting promise of an axios response will have extra
  # metadata in the format of { data, status, statusText, headers, config } but
  # we almost always want only the data from the response.
  pickData: (realFn) ->
    # return a new function whom arguments will be passed to real fn.
    (args...) ->
      # call real fn and get a Promise
      realFn(args...)
        # set an initial resolver which will resolve only the data for
        # concurrent resolvers.
        .then (response) -> response.data
