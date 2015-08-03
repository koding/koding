JUser                               = null
JAccount                            = null

Bongo                               = require 'bongo'
koding                              = require './../bongo'
request                             = require 'request'
querystring                         = require 'querystring'

{ daisy }                           = Bongo
{ expect }                          = require 'chai'
{ Relationship }                    = require 'jraphical'

{ TeamHandlerHelper
  generateRandomEmail
  generateRandomString
  RegisterHandlerHelper }           = require '../../../testhelper/testhelper'

# { generateGetTeamRequestParams
#   generateJoinTeamRequestParams
#   generateCreateTeamRequestParams } = TeamHandlerHelper

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
      requestParams = generateGetTeamRequestParams { email, method }
      queue.push ->
        request requestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 404
          expect(body)            .to.be.equal 'no user found'
          queue.next()

    queue.push -> done()

    daisy queue


  # it 'should send HTTP 200 if slug is valid using any method', (done) ->

  #   addRequestToQueue = (queue, method, requestParams) ->
  #     requestParams.method = method
  #     queue.push ->
  #       request requestParams, (err, res, body) ->
  #         expect(err)             .to.not.exist
  #         expect(res.statusCode)  .to.be.equal 200
  #         queue.next()

  #   queue                     = []
  #   methods                   = ['post', 'get', 'put', 'patch']
  #   randomEmail               = generateRandomEmail()
  #   getTeamRequestParams      = generateGetTeamRequestParams { groupSlug }

  #   createTeamRequestParams   = generateCreateTeamRequestParams
  #     body    :
  #       slug  : groupSlug

  #   queue.push ->
  #     request.post createTeamRequestParams, (err, res, body) ->
  #       expect(err)             .to.not.exist
  #       expect(res.statusCode)  .to.be.equal 200
  #       queue.next()

  #   for method in methods
  #     addRequestToQueue queue, method, getTeamRequestParams

  #   queue.push -> done()

  #   daisy queue
