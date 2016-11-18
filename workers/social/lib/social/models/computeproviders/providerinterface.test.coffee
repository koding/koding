ProviderInterface = require './providerinterface'

{ async
  expect
  withConvertedUser
  checkBongoConnectivity } = require '../../../../testhelper'

{ removeGeneratedCredentials
  withConvertedUserAndCredential
} = require '../../../../testhelper/models/computeproviders/credentialhelper'

{ withConvertedUserAnd } = require \
  '../../../../testhelper/models/computeproviders/computeproviderhelper'

JGroup   = require '../group'
JMachine = require '../computeproviders/machine'

# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.providerinterface', ->

  describe '#fetchCredentialData()', ->

    it 'it should be able fetch credential data ', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->

        ProviderInterface.fetchCredentialData client, credential, (err, credData) ->
          expect(err).to.not.exist
          expect(credData).to.be.an 'object'
          expect(credData.meta).to.be.an 'object'
          expect(credData.identifier).to.be.equal credential.identifier
          done()

  describe '#update()', ->

    it 'should fail to update machine when options is empty', (done) ->

      withConvertedUser ({ client, account, user }) ->
        client.r      = { account, user }
        expectedError = 'A valid machineId and an update option required.'

        options = {}
        ProviderInterface.update client, options, (err) ->
          expect(err?.message).to.be.equal expectedError
          done()


    it 'should be able to update machine when valid data provided', (done) ->

      withConvertedUserAnd ['ComputeProvider'], (data) ->
        { client, account, user, machine } = data
        group = null

        # Test purposes only ~ GG
        ProviderInterface.providerSlug = 'aws'

        queue = [

          (next) ->
            JGroup.one { slug : client.context.group }, (err, group_) ->
              expect(err).to.not.exist
              group = group_
              next()

          (next) ->
            client.r = { account, user, group }
            options = { machineId : machine._id.toString(), alwaysOn : false }
            ProviderInterface.update client, options, (err) ->
              expect(err?.message).to.not.exist
              next()

          (next) ->
            JMachine.one { _id : machine._id }, (err, machine_) ->
              expect(err).to.not.exist
              expect(machine_.meta.alwaysOn).to.be.falsy
              next()

          (next) ->
            client.r = { account, user, group }
            options = { machineId : machine._id.toString(), alwaysOn : true }
            ProviderInterface.update client, options, (err) ->
              expect(err?.message).to.not.exist
              next()

          (next) ->
            JMachine.one { _id : machine._id }, (err, machine_) ->
              expect(err).to.not.exist
              expect(machine_.meta.alwaysOn).to.be.truthy
              next()

        ]

        async.series queue, done



afterTests = -> after removeGeneratedCredentials

beforeTests()

runTests()

afterTests()
