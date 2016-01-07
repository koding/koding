Bongo                               = require 'bongo'
koding                              = require './../bongo'

{ daisy }                           = Bongo
{ expect }                          = require 'chai'
{ Relationship }                    = require 'jraphical'
{ generateRandomEmail
  generateRandomString }           = require '../../../testhelper'

{ generateGetTeamRequestParams
  generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'

request                             = require 'request'
querystring                         = require 'querystring'


# here we have actual tests
runTests = -> describe 'server.handlers.getteam', ->

  it 'should send HTTP 404 if group does not exist using any method', (done) ->

    queue                 = []
    methods               = ['post', 'get', 'put', 'patch']
    groupSlug             = generateRandomString()

    methods.forEach (method) ->
      getTeamRequestParams  = generateGetTeamRequestParams { method, groupSlug }

      queue.push ->
        request getTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 404
          expect(body)            .to.be.equal 'no group found'
          queue.next()

    queue.push -> done()

    daisy queue


  it 'should send HTTP 200 if slug is valid using any method', (done) ->

    queue                     = []
    methods                   = ['post', 'get', 'put', 'patch']
    groupSlug                 = generateRandomString()

    queue.push ->
      options = { body : { slug : groupSlug } }
      generateCreateTeamRequestParams options, (createTeamRequestParams) ->

        request.post createTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

    methods.forEach (method) ->
      getTeamRequestParams = generateGetTeamRequestParams { method, groupSlug }

      queue.push ->
        request getTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

    queue.push -> done()

    daisy queue


runTests()
