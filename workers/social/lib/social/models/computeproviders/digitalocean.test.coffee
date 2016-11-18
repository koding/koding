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
          expect(data.meta.image)      .to.be.equal 'ubuntu-14-04-x64'
          expect(data.meta.region)     .to.be.equal 'nyc2'
          expect(data.credential)      .to.be.equal options.credential
          done()


    describe 'when data is provided', ->

      it 'should create meta by given data', (done) ->

        client  = null

        options =
          region        : 'someRegion'
          credential    : 'someCredential'
          instance_type : 'someInstanceType'

        DigitalOcean.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta.type)          .to.be.equal 'digitalocean'
          expect(data.meta.image)         .to.be.equal 'ubuntu-14-04-x64'
          expect(data.meta.instance_type) .to.be.equal options.instance_type
          expect(data.meta.region)        .to.be.equal options.region
          expect(data.credential)         .to.be.equal options.credential
          done()


beforeTests()

runTests()
