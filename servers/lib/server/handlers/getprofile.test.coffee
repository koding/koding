{ async
  expect
  request
  generateRandomEmail
  generateRandomString }            = require '../../../testhelper'
{ generateRegisterRequestParams }   = require '../../../testhelper/handler/registerhelper'
{ generateGetProfileRequestParams } = require '../../../testhelper/handler/getprofilehelper'

JUser    = require '../../../models/user'
JAccount = require '../../../models/account'

# begin tests
describe 'server.handlers.getprofile', ->

  it 'should send HTTP 404 if user is not found for the given email.', (done) ->

    queue   = []
    methods = ['post', 'get', 'put', 'patch']
    email   = generateRandomEmail()

    methods.forEach (method) ->
      requestParams = generateGetProfileRequestParams { email, method }
      queue.push (next) ->
        request requestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 404
          expect(body).to.be.equal 'no user found'
          next()

    async.series queue, done


  it 'should send HTTP 200 if user is found for the given email.', (done) ->

    queue = []
    email = generateRandomEmail()

    registerRequestParams = generateRegisterRequestParams
      method              : 'post'
      body                :
        email             : email
        username          : generateRandomString()
        password          : 'testpass'
        passwordConfirm   : 'testpass'

    profileRequestParams  = generateGetProfileRequestParams { email, method : 'post' }

    queue.push (next) ->

      request registerRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 200
        next()

    queue.push (next) ->

      request profileRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 200
        next()

    async.series queue, done
