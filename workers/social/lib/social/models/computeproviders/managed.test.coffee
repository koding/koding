Managed = require './managed'

{ daisy
  expect
  withDummyClient
  withConvertedUser
  expectAccessDenied
  generateRandomString
  checkBongoConnectivity }          = require '../../../../testhelper'
{ generateProvisionerData
  withConvertedUserAndProvisioner } = require '../../../../testhelper/models/computeproviders/provisionerhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.managed', ->

  describe '#ping()', ->

    it 'should be able to ping', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r = { account }

        expectedPong = "#{Managed.providerSlug} VMs rulez #{account.profile.nickname}!"
        Managed.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal expectedPong
          done()


  describe '#create()', ->

    it 'should fail to create managed vm if ip address is not valid', (done) ->

      withConvertedUser ({ client, account, user }) ->
        client.r = { account, user, group : client.context.group }

        options =
          label       : generateRandomString()
          ipAddress   : '127.0.0.1'
          queryString : '1/2/3/4/5/6/7/8'

        expectedQueryString = "///////#{options.queryString.split('/').reverse()[0]}"
        Managed.create client, options, (err, managedVm) ->
          expect(err?.message).to.not.exist
          expect(managedVm.label).to.be.equal options.label
          expect(managedVm.meta).to.be.an 'object'
          expect(managedVm.meta.type).to.be.equal Managed.providerSlug
          expect(managedVm.meta.storage_size).to.be.equal 0
          expect(managedVm.meta.alwaysOn).to.be.falsy
          expect(managedVm.credential).to.be.equal user.username
          expect(managedVm.postCreateOptions).to.be.an 'object'
          expect(managedVm.postCreateOptions.queryString).to.be.equal expectedQueryString
          expect(managedVm.postCreateOptions.ipAddress).to.equal options.ipAddress
          done()


beforeTests()

runTests()


