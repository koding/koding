{ async
  expect
  request
  generateRandomString
  generateRandomUsername }                = require '../../../testhelper'
{ generateRegisterRequestParams }         = require '../../../testhelper/handler/registerhelper'
{ generateValidateUsernameRequestParams } = require '../../../testhelper/handler/validateusernamehelper'

JUser = require '../../../models/user'


# here we have actual tests
runTests = -> describe 'server.handlers.validateusername', ->

  it 'should send HTTP 404 if request method is not POST', (done) ->

    validateUsernameRequestParams = generateValidateUsernameRequestParams
      body       :
        username : generateRandomUsername()

    queue   = []
    methods = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push (next) ->
      validateUsernameRequestParams.method = method
      request validateUsernameRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 404
        next()

    for method in methods
      addRequestToQueue queue, method

    async.series queue, done


  it 'should send HTTP 400 if username is not set', (done) ->

    validateUsernameRequestParams      = generateValidateUsernameRequestParams()
    validateUsernameRequestParams.body = null

    request.post validateUsernameRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Bad request'
      done()


  it 'should send HTTP 400 if username is not in use but forbidden', (done) ->

    validateUsernameRequestParams = generateValidateUsernameRequestParams
      body       :
        username : JUser.bannedUserList[0]

    expectedBody = JSON.stringify { kodingUser : false, forbidden : true }
    request.post validateUsernameRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal expectedBody
      done()


  it 'should send HTTP 400 if username is in use', (done) ->

    username = generateRandomUsername()

    validateUsernameRequestParams = generateValidateUsernameRequestParams
      body       :
        username : username

    registerRequestParams = generateRegisterRequestParams
      body       :
        username : username

    queue = [

      (next) ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.be.equal ''
          next()

      (next) ->
        # expecting existing username to return 400
        expectedBody = JSON.stringify { kodingUser : true, forbidden : false }
        request.post validateUsernameRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal expectedBody
          next()

    ]

    async.series queue, done


  it 'should send HTTP 400 if username does not have valid character length', (done) ->

    { minLength, maxLength } = JUser.getValidUsernameLengthRange()

    queue = [

      (next) ->
        # expecting username that has less then minimum character length to return 400
        validateUsernameRequestParams = generateValidateUsernameRequestParams
          body       :
            username : generateRandomString --minLength

        expectedBody = JSON.stringify { kodingUser : false, forbidden : true }
        request.post validateUsernameRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal expectedBody
          next()

      (next) ->
        # expecting username that has more than maximum character length to return 400
        validateUsernameRequestParams = generateValidateUsernameRequestParams
          body       :
            username : generateRandomString ++maxLength

        expectedBody = JSON.stringify { kodingUser : false, forbidden : true }
        request.post validateUsernameRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal expectedBody
          next()

    ]

    async.series queue, done


  it 'should send HTTP 200 if username is not in use, not forbidden, has valid range', (done) ->

    expectedBody = JSON.stringify
      kodingUser : false
      forbidden  : false

    { minLength, maxLength } = JUser.getValidUsernameLengthRange()

    queue = [

      (next) ->
        # expecting username that has average character length to return 200
        validateUsernameRequestParams = generateValidateUsernameRequestParams
          body       :
            username : generateRandomString Math.round (maxLength + minLength) / 2

        request.post validateUsernameRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.be.equal expectedBody
          next()

      (next) ->
        # expecting username that has minimum character length to return 200
        validateUsernameRequestParams = generateValidateUsernameRequestParams
          body       :
            username : generateRandomString minLength

        request.post validateUsernameRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.be.equal expectedBody
          next()

      (next) ->
        # expecting username that has maximum character length to return 200
        validateUsernameRequestParams = generateValidateUsernameRequestParams
          body       :
            username : generateRandomString maxLength

        request.post validateUsernameRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .to.be.equal expectedBody
          next()

    ]

    async.series queue, done


runTests()
