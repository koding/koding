{ daisy
  expect
  withConvertedUser
  checkBongoConnectivity }      = require '../../../../testhelper'
{ withConvertedUserAndCredential } = require '../../../../testhelper/models/computeproviders/credentialhelper'

JGroup  = require '../group'
Koding = require './koding'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.koding', ->

  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r = { account }
        expectedPong = "#{Koding.providerSlug} is the best #{account.profile.nickname}!"
        Koding.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal expectedPong
          done()


  describe '#fetchAvailable()', ->

    it 'should be able fech data', (done) ->

      Koding.fetchAvailable null, {}, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.be.an 'array'
        done()


beforeTests()

runTests()
