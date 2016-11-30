{ async
  expect
  withConvertedUser
  checkBongoConnectivity } = require '../../../../testhelper'

Aws = require './aws'

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


  describe '#secretKeys', ->

    it 'should be equal to aws sensitive keys', ->

      expect(Aws.secretKeys).to.be.deep.equal ['access_key', 'secret_key']


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


beforeTests()

runTests()
