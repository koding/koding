{ async
  expect
  request
  generateRandomEmail
  generateRandomString
  generateRandomUsername }        = require '../../../testhelper'
{ testCsrfToken }                 = require '../../../testhelper/handler'
{ generateRecoverRequestParams }  = require '../../../testhelper/handler/recoverhelper'
{ generateRegisterRequestParams } = require '../../../testhelper/handler/registerhelper'


# here we have actual tests
runTests = -> describe 'server.handlers.recover', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken generateRecoverRequestParams, 'post', done


  it 'should send HTTP 404 if request method is not POST', (done) ->

    recoverRequestParams = generateRecoverRequestParams
      body    :
        email : generateRandomEmail()

    queue   = []
    methods = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push (next) ->
      recoverRequestParams.method = method
      request recoverRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 404
        next()

    for method in methods
      addRequestToQueue queue, method

    async.series queue, done


  it 'should send HTTP 400 if email params is not set', (done) ->

    recoverRequestParams = generateRecoverRequestParams
      body    :
        email : ''

    request.post recoverRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Invalid email!'
      done()


  it 'should send HTTP 200 if email is valid', (done) ->

    email = generateRandomEmail()

    queue = [

      (next) ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body    :
            email : email

        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        # expecting recover to succeed using newly registered user email
        recoverRequestParams = generateRecoverRequestParams
          body    :
            email : email

        request.post recoverRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.be.equal ''
          next()

    ]

    async.series queue, done


  it 'should send HTTP 200 if email is not registered', (done) ->

    recoverRequestParams = generateRecoverRequestParams
      body    :
        email : generateRandomEmail()

    request.post recoverRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 200
      expect(body).to.be.equal ''
      done()


runTests()
