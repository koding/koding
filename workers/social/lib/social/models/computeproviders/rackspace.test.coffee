Rackspace      = require './rackspace'

{ expect
  withConvertedUser
  checkBongoConnectivity } = require '../../../../testhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.rackspace', ->

  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r = { account }

        Rackspace.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal "Rackspace is cool #{account.profile.nickname}!"
          done()


  describe '#create()', ->

    describe 'when no data is provided', ->

      it 'should create default meta data', (done) ->

        client  = null
        options = { credential : 'someCredential' }

        Rackspace.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)       .to.be.equal 'rackspace'
          expect(data.meta.imageId)    .to.be.equal 'bb02b1a3-bc77-4d17-ab5b-421d89850fca'
          expect(data.meta.flavorId)   .to.be.equal '2'
          expect(data.meta.region)     .to.be.equal 'IAD'
          expect(data.credential)      .to.be.equal options.credential
          done()


    describe 'when data is provided', ->

      it 'should create meta by given data', (done) ->

        client  = null

        options =
          region       : 'someRegion'
          imageId      : 'someImageId'
          credential   : 'someCredential'
          instanceType : 'someFlavorId'

        Rackspace.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)       .to.be.equal 'rackspace'
          expect(data.meta.imageId)    .to.be.equal options.imageId
          expect(data.meta.flavorId)   .to.be.equal options.instanceType
          expect(data.meta.region)     .to.be.equal options.region
          expect(data.credential)      .to.be.equal options.credential
          done()


  describe '#fetchAvailable()', ->

    it 'should fetch aws pricing', (done) ->

      client = null

      Rackspace.fetchAvailable client, {}, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.be.an 'array'
        done()


beforeTests()

runTests()
