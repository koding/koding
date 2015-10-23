{ daisy
  expect
  request
  generateRandomString } = require '../index'


expect403 = (callback) ->

  return (err, res, body) ->
    expect(err).to.not.exist
    expect(res.statusCode).to.be.equal 403
    expect(body).to.be.equal '_csrf token is not valid'
    callback()


testCsrfToken = (generateHandlerRequestParams, method, options, callback) ->

  [options, callback] = [callback, options]  unless callback

  paramsObjects = [
    {
      csrfCookie : false
    }
    {
      body       :
        _csrf    : ''
    }
    {
      body       :
        _csrf    : generateRandomString()
      csrfCookie : generateRandomString()
    }
  ]

  queue = []

  paramsObjects.forEach (params) ->

    if options?.generateParamsAsync
      queue.push ->
        generateHandlerRequestParams params, (requestParams) ->
          request[method] requestParams, expect403 ->
            queue.next()

    else
      queue.push ->
        requestParams = generateHandlerRequestParams params
        request[method] requestParams, expect403 ->
          queue.next()

  queue.push -> callback()

  daisy queue


module.exports = {
  testCsrfToken
}


