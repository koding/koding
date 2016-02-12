JProvisioner = require './provisioner'

{ async
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
runTests = -> describe 'workers.social.models.computeproviders.provisioner', ->

  describe '#create()', ->

    it 'should fail to create provisioner if user doesnt have permission', (done) ->

      expectAccessDenied JProvisioner, 'create', data = {}, done


    it 'should be able to create provisioner when valid data provided', (done) ->

      withConvertedUser ({ client, account }) ->
        provisionerData = generateProvisionerData()
        expectedSlug    = "#{account.profile.nickname}/#{provisionerData.slug}"

        JProvisioner.create client, provisionerData, (err, provisioner) ->
          expect(err).to.not.exist
          expect(provisioner).to.exist
          expect(provisioner.type).to.be.equal provisionerData.type
          expect(provisioner.accessLevel).to.be.equal provisionerData.accessLevel
          expect(provisioner.slug).to.be.equal expectedSlug
          expect(provisioner.content).to.be.an 'object'
          expect(provisioner.content).to.be.deep.equal provisionerData.content
          expect(provisioner.contentSum).to.be.equal provisionerData.contentSum
          expect(provisioner.contentSum).to.be.equal provisionerData.contentSum
          expect(provisioner.originId).to.exist
          expect(provisioner.group).to.be.equal client.context.group
          done()


    it 'should fail to craete provisioner if type is missing', (done) ->

      withConvertedUserAndProvisioner ({ client, provisioner }) ->

        queue = [

          (next) ->
            provisionerData = generateProvisionerData
              type : null

            JProvisioner.create client, provisionerData, (err, provisioner_) ->
              expect(err?.message).to.be.equal 'Type missing.'
              next()

          (next) ->
            provisionerData = generateProvisionerData
              type : 'someInvalidType'

            JProvisioner.create client, provisionerData, (err, provisioner_) ->
              expect(err?.message).to.be.equal 'Type is not supported for now.'
              next()

        ]

        async.series queue, done


    it 'should fail to craete provisioner if content script is not provided', (done) ->

      withConvertedUser ({ client }) ->

        queue = [

          (next) ->
            provisionerData = generateProvisionerData
              content : null

            JProvisioner.create client, provisionerData, (err, provisioner_) ->
              expect(err?.message).to.be.equal 'Content missing.'
              next()

          (next) ->
            provisionerData = generateProvisionerData
              content : { script : null }

            JProvisioner.create client, provisionerData, (err, provisioner_) ->
              expect(err?.message).to.be.equal 'Type shell requires a `script`'
              next()

        ]

        async.series queue, done


  describe '#some$', ->

    it 'should fail to fetch provisioner data if user doesnt have permission', (done) ->

      expectAccessDenied JProvisioner, 'some$', selector = {}, options = {}, done


  it 'should be able to fetch provisioner data with valid request', (done) ->

    withConvertedUserAndProvisioner ({ client, provisioner }) ->
      selector = { slug : provisioner.slug }
      JProvisioner.some$ client, selector, (err, provisioners) ->
        expect(err).to.not.exist
        expect(provisioners).to.be.an 'array'
        expect(provisioners[0].slug).to.be.equal provisioner.slug
        done()


  describe '#one$', ->

    it 'should fail to fetch provisioner data if user doesnt have permission', (done) ->

      expectAccessDenied JProvisioner, 'one$', selector = {}, options = {}, done


  it 'should be able to fetch provisioner data with valid request', (done) ->

    withConvertedUserAndProvisioner ({ client, provisioner }) ->
      selector = { slug : provisioner.slug }
      JProvisioner.one$ client, selector, (err, provisioner_) ->
        expect(err).to.not.exist
        expect(provisioner_).to.be.an 'object'
        expect(provisioner_.slug).to.be.equal provisioner.slug
        done()


  describe 'delete()', ->

    it 'should fail to delete provisioner data if user doesnt have permission', (done) ->

      withConvertedUserAndProvisioner ({ provisioner }) ->
        expectAccessDenied provisioner, 'delete', selector = {}, options = {}, done


  it 'should be able to delete provisioner of the given client', (done) ->

    withConvertedUserAndProvisioner ({ client, provisioner }) ->

      queue = [

        (next) ->
          JProvisioner.one { slug : provisioner.slug }, (err, provisioner) ->
            expect(err).to.not.exist
            expect(provisioner).to.exist
            next()

        (next) ->
          provisioner.delete client, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          JProvisioner.one { slug : provisioner.slug }, (err, provisioner) ->
            expect(err).to.not.exist
            expect(provisioner).to.not.exist
            next()

      ]

      async.series queue, done


  describe 'setAccess()', ->

    it 'should fail to change access of provisioner if user doesnt have permission', (done) ->

      withConvertedUserAndProvisioner ({ provisioner }) ->
        expectAccessDenied provisioner, 'setAccess', accessLevel = 'someLevel', done


  it 'should be able to set access level of provisioner', (done) ->

    withConvertedUserAndProvisioner ({ client, provisioner }) ->

      queue = [

        (next) ->
          provisioner.setAccess client, 'public', (err) ->
            expect(err?.message).to.not.exist
            expect(provisioner.accessLevel).to.be.equal 'public'
            next()

        (next) ->
          JProvisioner.one { slug : provisioner.slug }, (err, provisioner_) ->
            expect(err).to.not.exist
            expect(provisioner_.accessLevel).to.be.equal 'public'
            next()

      ]

      async.series queue, done


  describe 'update$()', ->

    it 'should fail to update provisioner if user doesnt have permission', (done) ->

      withConvertedUserAndProvisioner ({ provisioner }) ->
        expectAccessDenied provisioner, 'update$', data = {}, done


  it 'should be able to update provisioner data with valid request', (done) ->

    withConvertedUserAndProvisioner ({ client, account, provisioner }) ->

      expectedSlug = "#{account.profile.nickname}/someNewSlug"

      queue = [

        (next) ->
          provisioner.update$ client, {}, (err) ->
            expect(err?.message).to.be.equal 'Nothing to update'
            next()

        (next) ->
          provisioner.update$ client, { slug : 'someNewSlug' }, (err) ->
            expect(err).to.not.exist
            expect(provisioner.slug).to.be.equal expectedSlug
            next()

        (next) ->
          JProvisioner.one { slug : expectedSlug }, (err, provisioner_) ->
            expect(err).to.not.exist
            expect(provisioner_).to.exist
            next()

        (next) ->
          provisioner.update$ client, { label : 'someNewLabel' }, (err) ->
            expect(err).to.not.exist
            expect(provisioner.label).to.be.equal 'someNewLabel'
            next()

        (next) ->
          JProvisioner.one { label : 'someNewLabel' }, (err, provisioner_) ->
            expect(err).to.not.exist
            expect(provisioner_).to.exist
            next()

      ]

      async.series queue, done



beforeTests()

runTests()
