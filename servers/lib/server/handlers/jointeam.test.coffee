{ Relationship }                    = require 'jraphical'
{ async
  expect
  request
  convertToArray
  generateRandomEmail
  generateRandomString
  checkBongoConnectivity }          = require '../../../testhelper'
{ testCsrfToken }                   = require '../../../testhelper/handler'
{ generateRegisterRequestParams }   = require '../../../testhelper/handler/registerhelper'
{ generateJoinTeamRequestParams
  generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'

JUser       = require '../../../models/user'
JGroup      = require '../../../models/group'
JAccount    = require '../../../models/account'
JInvitation = require '../../../models/invitation'


beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'server.handlers.jointeam', ->

  it 'should send HTTP 403 if _csrf token is invalid', (done) ->

    testCsrfToken generateJoinTeamRequestParams, 'post', done


  it 'should send HTTP 301 if redirect is set', (done) ->

    postParams = generateJoinTeamRequestParams
      body        :
        redirect  : 'www.someurl.com'

    request.post postParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 301
      done()


  it 'should send HTTP 400 if username is not set', (done) ->

    joinTeamRequestParams = generateJoinTeamRequestParams
      body       :
        username : ''

    expectedBody = 'Errors were encountered during validation: username'
    request.post joinTeamRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal expectedBody
      done()


  it 'should send HTTP 400 if passwords do not match', (done) ->

    joinTeamRequestParams = generateJoinTeamRequestParams
      body              :
        password        : 'somePassword'
        passwordConfirm : 'anotherPassword'

    request.post joinTeamRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Passwords must match!'
      done()


beforeTests()

runTests()
