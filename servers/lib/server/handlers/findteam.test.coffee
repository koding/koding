{ async
  expect
  request
  checkBongoConnectivity
  generateRandomEmail
  generateRandomString
  generateRandomUsername }          = require '../../../testhelper'
{ testCsrfToken }                   = require '../../../testhelper/handler'
FindTeamHelper                      = require '../../../testhelper/handler/findteamhelper'
{ generateRegisterRequestParams }   = require '../../../testhelper/handler/registerhelper'
{ generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'


beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = -> describe 'server.handlers.findteam', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken FindTeamHelper.generateRequestParams, 'post', done


  it 'should send HTTP 404 if request method is not POST', (done) ->

    requestParams = FindTeamHelper.generateRequestParams
      body    :
        email : generateRandomEmail()

    queue   = []
    methods = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push (next) ->
      requestParams.method = method
      request requestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 404
        next()

    for method in methods
      addRequestToQueue queue, method

    async.series queue, done


  it 'should send HTTP 400 if email param is not set', (done) ->

    requestParams = FindTeamHelper.generateRequestParams
      body    :
        email : ''

    request.post requestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Invalid email!'
      done()


  it 'should send HTTP 403 if email is valid but team list is empty', (done) ->

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
        requestParams = FindTeamHelper.generateRequestParams
          body    :
            email : email

        request.post requestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 403
          expect(body).to.be.equal 'Empty team list'
          next()
    ]

    async.series queue, done


  it 'should send HTTP 200 if email is not registered', (done) ->

    requestParams = FindTeamHelper.generateRequestParams
      body    :
        email : generateRandomEmail()

    request.post requestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 200
      expect(body).to.be.equal ''
      done()


  it 'should send HTTP 200 if user is related to any team', (done) ->

    slug  = generateRandomString()
    email = generateRandomEmail()

    registerRequestParams = generateRegisterRequestParams
      body : { email }

    queue = [

      (next) ->
        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        options = { body : { slug, invitees : email, companyName : slug } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          request.post createTeamRequestParams, (err, res, body) ->
            expect(err).to.not.exist
            expect(res.statusCode).to.be.equal 200
            next()

      (next) ->
        requestParams = FindTeamHelper.generateRequestParams
          body    : { email }

        request.post requestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.be.equal ''
          next()
    ]

    async.series queue, done


beforeTests()
runTests()
