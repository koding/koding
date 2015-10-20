Azure = require './azure'

{ expect
  withConvertedUser
  checkBongoConnectivity
  generateDummyUserFormData } = require '../../../../testhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.azure', ->

  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      userFormData = generateDummyUserFormData()

      withConvertedUser { userFormData }, (data) ->

        { client, account } = data

        Azure.ping client, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal "Azure is cool #{client.connection.delegate.profile.nickname}!"
          done()


beforeTests()

runTests()

