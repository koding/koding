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


    it 'should return meta data and credential', (done) ->

      client = null

      options =
        region        : 'us-east-1'
        storage       : 8
        instanceType : 't2.micro'

      Aws.create client, options, (err, data) ->
        expect(err).to.not.exist
        expect(data.meta.type)            .to.be.equal Aws.providerSlug
        expect(data.meta.region)          .to.be.equal options.region
        expect(data.meta.instance_type)   .to.be.equal options.instanceType
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

