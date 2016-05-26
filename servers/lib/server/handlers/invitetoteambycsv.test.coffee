parser = require 'csv-parse'
{ withConvertedUser } = require '../../../../workers/social/testhelper'

{ async
  expect
  request
  generateUrl
  generateRandomEmail
  generateRandomString
  checkBongoConnectivity
  generateRequestParamsEncodeBody } = require '../../../testhelper'

before (done) -> checkBongoConnectivity done

describe 'server.handlers.invitetoteambycsv', ->

  it 'should be parse broken csv', (done) ->
    runTest brokenFile, done

  it 'should be able to process 500 items at once', (done) ->
    runTest lotsOfInvitations, done

runTest = (testData, done) ->
  password = 'testpass'
  registerRequestParams =
    email: generateRandomEmail()
    username: generateRandomString()
    password: password
    passwordConfirm: password
    agree: 'on'

  withConvertedUser { createGroup: true, role: 'admin', userFormData: registerRequestParams }, (admin) ->
    requestParams = generateRequestParamsEncodeBody
      url      : generateUrl { route : '-/teams/invite-by-csv' }
      clientId : admin.client.sessionToken

    req = request.post requestParams, (err, resp, body) ->
      expect(err).to.not.exist
      expect(resp.statusCode).to.be.equal 200
      validateInvitation testData, (err) ->
        expect(err).to.not.exist
        done()

    form = req.form()
    form.append 'file', testData, {
      filename: 'invitations.csv'
      contentType: 'multipart/form-data'
    }

validateInvitation = (data, callback) ->
  parser data, require('./invitetoteambycsv').parserOpts, (err, data) ->
    return callback err if err

    JInvitation = require '../../../models/invitation'
    # 4 is a RANDOM NUMBER OK?.
    JInvitation.one { email: data[4].email }, (err, invitation) ->
      return callback err if err
      return callback new Error 'invitation is not found' if not invitation

      return callback null

brokenFile = '''
  this is not an valid line that contains email
  cihangir1@koding.com,   cihangir1,savas1  ,admin
  cihangir2@koding.com,,savas2,
  cihangir3@koding.com,cihangir3,

  cihangir4@koding.com,cihangir4,savas4,hulo
  cihangir5@koding.com,netflix,member


  cihangir6@koding.com.cihangir6.savas6.member
  '''

# [ { email: 'cihangir1@koding.com',
#     firstName: 'cihangir1',
#     lastName: 'savas1',
#     role: 'admin' },
#   { email: 'cihangir2@koding.com',
#     firstName: '',
#     lastName: 'savas2',
#     role: '' },
#   { email: 'cihangir3@koding.com',
#     firstName: 'cihangir3',
#     lastName: '' },
#   { email: 'cihangir4@koding.com',
#     firstName: 'cihangir4',
#     lastName: 'savas4',
#     role: 'hulo' },
#   { email: 'cihangir5@koding.com',
#     firstName: 'netflix',
#     lastName: 'member' },
#   { email: 'cihangir6@koding.com.cihangir6.savas6.member' }
# ] }

lotsOfInvitations = (generateRandomEmail() for i in [1...500]).join('\n')
