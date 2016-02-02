{ async
  expect
  request
  querystring
  generateRandomEmail
  generateRandomString
  generateRandomUsername }        = require '../../../testhelper'
{ generateValidateRequestBody
  generateValidateRequestParams } = require '../../../testhelper/handler/validatehelper'


# here we have actual tests
runTests = -> describe 'server.handlers.validate', ->

  it 'should send HTTP 404 if request method is not POST', (done) ->

    validateRequestParams = generateValidateRequestParams
      body       :
        username : generateRandomUsername()

    queue   = []
    methods = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push (next) ->
      validateRequestParams.method = method
      request validateRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 404
        next()

    for method in methods
      addRequestToQueue queue, method

    async.series queue, done


  it 'should send HTTP 400 if fields params is not set', (done) ->

    validateRequestParams      = generateValidateRequestParams()
    validateRequestParams.body = null

    request.post validateRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Bad request'
      done()


  it.skip 'should send HTTP 200 if both email and username is not in use', (done) ->

    validateRequestParams = generateValidateRequestParams()

    # querystring fails encoding nested objects
    stringifiedFields = JSON.stringify
      email    : generateRandomEmail()
      username : generateRandomUsername()

    validateRequestParams.body = "fields=#{stringifiedFields}"

    request.post validateRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'asd'
      queue.next()



runTests()
