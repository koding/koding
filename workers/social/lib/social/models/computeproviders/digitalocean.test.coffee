DigitalOcean      = require './digitalocean'

{ expect
  withConvertedUser
  checkBongoConnectivity } = require '../../../../testhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.digitalocean', ->

  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r = { account }

        DigitalOcean.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal "DigitalOcean is better #{account.profile.nickname}!"
          done()


  describe '#create()', ->

    describe 'when no data is provided', ->

      it 'should create default meta data', (done) ->

        client  = null
        options = { credential : 'someCredential' }

        DigitalOcean.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)       .to.be.equal 'digitalocean'
          expect(data.meta.image)      .to.be.equal 'ubuntu-13-10-x64'
          expect(data.meta.size)       .to.be.equal '512mb'
          expect(data.meta.region)     .to.be.equal 'sfo1'
          expect(data.credential)      .to.be.equal options.credential
          done()


    describe 'when data is provided', ->

      it 'should create meta by given data', (done) ->

        client  = null

        options =
          region       : 'someRegion'
          credential   : 'someCredential'
          instanceType : 'someInstanceType'

        DigitalOcean.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)       .to.be.equal 'digitalocean'
          expect(data.meta.image)      .to.be.equal 'ubuntu-13-10-x64'
          expect(data.meta.size)       .to.be.equal options.instanceType
          expect(data.meta.region)     .to.be.equal options.region
          expect(data.credential)      .to.be.equal options.credential
          done()


  describe '#fetchAvailable()', ->

    it 'should fetch aws pricing', (done) ->

      client = null

      DigitalOcean.fetchAvailable client, {}, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.be.an 'array'
        done()


beforeTests()

runTests()

