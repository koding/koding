JUser            = null
JAccount         = null

Bongo            = require 'bongo'
koding           = require './../bongo'
request          = require 'request'

{ daisy }        = Bongo
{ expect }       = require 'chai'

{ RegisterHandlerHelper
  generateRandomEmail
  generateRandomString } = require '../../../testhelper'

{ generateGetProfileRequestParams
  generateRegisterRequestParams } = RegisterHandlerHelper

# begin tests
describe 'server.handlers.getprofile', ->

  beforeEach (done) ->

    # including models before each test case, requiring them outside of
    # tests suite is causing undefined errors
    {
      JUser
      JAccount
    } = koding.models

    done()


  it 'should send HTTP 404 if user is not found for the given email.', (done) ->

    queue   = []
    methods = ['post', 'get', 'put', 'patch']
    email   = generateRandomEmail()

    methods.forEach (method) ->
      requestParams = generateGetProfileRequestParams { email, method }
      queue.push ->
        request requestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 404
          expect(body)            .to.be.equal 'no user found'
          queue.next()

    queue.push -> done()

    daisy queue


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

    queue.push ->

      request registerRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 200
        queue.next()

    queue.push ->

      request profileRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 200
        queue.next()

    queue.push -> done()

    daisy queue
