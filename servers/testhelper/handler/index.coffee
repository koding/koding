{ daisy
  expect
  request
  generateRandomString } = require '../index'

testCsrfToken = (generateHandlerRequestParams, method, callback) ->

  [method, callback] = [callback, method]  unless callback
  method ?= 'post'

  queue = [

    ->
      # sending _csrf parameter in body, but csrf cookie is not set
      handlerRequestParams = generateHandlerRequestParams
        csrfCookie : false

      request[method] handlerRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(body).to.be.equal '_csrf token is not valid'
        queue.next()

    ->
      # sending csrf cookie but not sending _csrf parameter in the body
      handlerRequestParams = generateHandlerRequestParams
        body    :
          _csrf : ''

      request[method] handlerRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(body).to.be.equal '_csrf token is not valid'
        queue.next()

    ->
      # sending different csrf tokens
      handlerRequestParams = generateHandlerRequestParams
        body       :
          _csrf    : generateRandomString()
        csrfCookie : generateRandomString()

      request[method] handlerRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(body).to.be.equal '_csrf token is not valid'
        queue.next()

    -> callback()

  ]

  daisy queue


module.exports = {
  testCsrfToken
}
