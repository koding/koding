Bongo                               = require 'bongo'
koding                              = require './../bongo'

{ daisy }                           = Bongo
{ expect }                          = require 'chai'
{ Relationship }                    = require 'jraphical'
{ TeamHandlerHelper
  generateRandomEmail
  generateRandomString
  RegisterHandlerHelper }           = require '../../../testhelper'

{ generateGetTeamRequestParams
  generateJoinTeamRequestParams
  generateCreateTeamRequestParams } = TeamHandlerHelper

request                             = require 'request'
querystring                         = require 'querystring'

JUser                               = null
JGroup                              = null
JAccount                            = null
JSession                            = null
JInvitation                         = null


# here we have actual tests
runTests = -> describe 'server.handlers.getteam', ->

  beforeEach (done) ->

    # including models before each test case, requiring them outside of
    # tests suite is causing undefined errors
    { JUser
      JGroup
      JAccount
      JSession
      JInvitation } = koding.models

    done()


  it 'should send HTTP 404 if group does not exist using any method', (done) ->

    addRequestToQueue = (queue, method, requestParams) ->
      requestParams.method = method
      queue.push ->
        request requestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 404
          expect(body)            .to.be.equal 'no group found'
          queue.next()

    queue                 = []
    methods               = ['post', 'get', 'put', 'patch']
    groupSlug             = generateRandomString()
    getTeamRequestParams  = generateGetTeamRequestParams { groupSlug }

    for method in methods
      addRequestToQueue queue, method, getTeamRequestParams

    queue.push -> done()

    daisy queue


  it 'should send HTTP 200 if slug is valid using any method', (done) ->

    addRequestToQueue = (queue, method, requestParams) ->
      requestParams.method = method
      queue.push ->
        request requestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

    queue                     = []
    methods                   = ['post', 'get', 'put', 'patch']
    groupSlug                 = generateRandomString()
    getTeamRequestParams      = generateGetTeamRequestParams { groupSlug }

    createTeamRequestParams   = generateCreateTeamRequestParams
      body    :
        slug  : groupSlug

    queue.push ->
      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 200
        queue.next()

    for method in methods
      addRequestToQueue queue, method, getTeamRequestParams

    queue.push -> done()

    daisy queue


runTests()

