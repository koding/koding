Aws      = require './aws'

{ expect
  withConvertedUser
  checkBongoConnectivity
  generateDummyUserFormData } = require '../../../../testhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.aws', ->

  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      userFormData = generateDummyUserFormData()

      withConvertedUser { userFormData }, (data) ->

        { client, account } = data
        client.r            = { account }

        Aws.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal "#{Aws.providerSlug} rulez #{account.profile.nickname}!"
          done()


  describe '#create()', ->

    it 'should fail when storage is not a number', (done) ->

      client = null

      Aws.create client, { storage : 'notaNumber' }, (err, data) ->
        expect(err?.message).to.be.equal 'Requested storage size is not valid.'
        done()


    describe 'when data is not provided', ->

      it 'should create default meta data', (done) ->

        client  = null
        options = {}

        Aws.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)            .to.be.equal Aws.providerSlug
          expect(data.meta.region)          .to.be.equal 'us-east-1'
          expect(data.meta.instance_type)   .to.be.equal 't2.micro'
          expect(data.credential)           .to.be.equal options.credential
          expect(data.meta.source_ami)      .to.not.exist
          done()


    describe 'when data is provided', ->

      it 'should create meta by given data', (done) ->

        client = null

        options =
          ami           : 'someAmi'
          region        : 'someRegion'
          storage       : 2
          credential    : 'someCredential'
          instanceType  : 'someInstanceType'

        Aws.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)            .to.be.equal Aws.providerSlug
          expect(data.meta.region)          .to.be.equal options.region
          expect(data.meta.instance_type)   .to.be.equal options.instanceType
          expect(data.credential)           .to.be.equal options.credential
          expect(data.meta.source_ami)      .to.be.equal options.ami
          done()
        

  describe '#fetchAvailable()', ->

    it 'should fetch aws pricing', (done) ->

      client = null

      Aws.fetchAvailable client, {}, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.be.an 'array'
        done()


beforeTests()

runTests()

