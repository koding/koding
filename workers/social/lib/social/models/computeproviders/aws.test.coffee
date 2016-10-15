{ async
  expect
  withConvertedUser
  checkBongoConnectivity } = require '../../../../testhelper'

{ withConvertedUserAnd } = require \
  '../../../../testhelper/models/computeproviders/computeproviderhelper'

Aws      = require './aws'
JGroup   = require '../group'
JMachine = require '../computeproviders/machine'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.aws', ->

  describe '#providerSlug', ->

    it 'should be equal to aws', ->

      expect(Aws.providerSlug).to.be.equal 'aws'


  describe '#bootstrapKeys', ->

    it 'should be equal to aws bootstrap keys', ->

      expect(Aws.bootstrapKeys).to.be.deep.equal ['key_pair', 'rtb', 'acl']


  describe '#sensitiveKeys', ->

    it 'should be equal to aws sensitive keys', ->

      expect(Aws.sensitiveKeys).to.be.deep.equal ['access_key', 'secret_key']


  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r = { account }

        Aws.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal "#{Aws.providerSlug} rulez #{account.profile.nickname}!"
          done()


  describe '#create()', ->

    describe 'when data is not provided', ->

      it 'should create default meta data', (done) ->

        client  = null
        options = {}

        Aws.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)            .to.be.equal Aws.providerSlug
          expect(data.meta.region)          .to.be.equal 'us-east-1'
          expect(data.meta.instance_type)   .to.be.equal 't2.nano'
          expect(data.credential)           .to.be.equal options.credential
          done()


    describe 'when data is provided', ->

      it 'should create meta by given data', (done) ->

        client = null

        options =
          image         : 'someAmi'
          region        : 'someRegion'
          storage_size  : 2
          credential    : 'someCredential'
          instance_type : 'someInstanceType'

        Aws.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)            .to.be.equal Aws.providerSlug
          expect(data.meta.region)          .to.be.equal options.region
          expect(data.meta.instance_type)   .to.be.equal options.instance_type
          expect(data.credential)           .to.be.equal options.credential
          expect(data.meta.image)           .to.be.equal options.image
          done()


  describe '#update()', ->

    it 'should fail to update machine when options is empty', (done) ->

      withConvertedUser ({ client, account, user }) ->
        client.r      = { account, user }
        expectedError = 'A valid machineId and an update option required.'

        options = {}
        Aws.update client, options, (err) ->
          expect(err?.message).to.be.equal expectedError
          done()


    it 'should be able to update machine when valid data provided', (done) ->

      withConvertedUserAnd ['ComputeProvider'], (data) ->
        { client, account, user, machine } = data
        group = null

        queue = [

          (next) ->
            JGroup.one { slug : client.context.group }, (err, group_) ->
              expect(err).to.not.exist
              group = group_
              next()

          (next) ->
            client.r = { account, user, group }
            options = { machineId : machine._id.toString(), alwaysOn : false }
            Aws.update client, options, (err) ->
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
            Aws.update client, options, (err) ->
              expect(err?.message).to.not.exist
              next()

          (next) ->
            JMachine.one { _id : machine._id }, (err, machine_) ->
              expect(err).to.not.exist
              expect(machine_.meta.alwaysOn).to.be.truthy
              next()

        ]

        async.series queue, done


beforeTests()

runTests()
