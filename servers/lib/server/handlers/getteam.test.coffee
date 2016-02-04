{ Relationship }                    = require 'jraphical'
{ async
  expect
  request
  querystring
  generateRandomEmail
  generateRandomString
  checkBongoConnectivity }          = require '../../../testhelper'
{ generateGetTeamRequestParams
  generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'


beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'server.handlers.getteam', ->

  it 'should send HTTP 404 if group does not exist using any method', (done) ->

    queue     = []
    methods   = ['post', 'get', 'put', 'patch']
    groupSlug = generateRandomString()

    methods.forEach (method) ->
      getTeamRequestParams = generateGetTeamRequestParams { method, groupSlug }

      queue.push (next) ->
        request getTeamRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 404
          expect(body).to.be.equal 'no group found'
          next()

    async.series queue, done


  it 'should send HTTP 200 if slug is valid using any method', (done) ->

    queue     = []
    methods   = ['post', 'get', 'put', 'patch']
    groupSlug = generateRandomString()

    queue.push (next) ->
      options = { body : { slug : groupSlug } }
      generateCreateTeamRequestParams options, (createTeamRequestParams) ->

        request.post createTeamRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

    methods.forEach (method) ->
      getTeamRequestParams = generateGetTeamRequestParams { method, groupSlug }

      queue.push (next) ->
        request getTeamRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

    async.series queue, done


beforeTests()

runTests()
