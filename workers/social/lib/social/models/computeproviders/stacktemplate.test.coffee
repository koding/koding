StackTemplate = require './stacktemplate'

{ daisy
  expect
  withDummyClient
  withConvertedUser
  generateRandomString
  checkBongoConnectivity }    = require '../../../../testhelper'
{ generateStackTemplateData } = require '../../../../testhelper/models/computeproviders/stacktemplatehelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.stacktemplate', ->

  describe '#create()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to create stack template', (done) ->

        withDummyClient ({ client }) ->

          StackTemplate.create client, {}, (err, template) ->
            expect(err?.message).to.be.equal 'Access denied'
            done()


    describe 'when user has the permission', ->

      it 'should fail if title is not set', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplateData = generateStackTemplateData client
          StackTemplate.create client, stackTemplateData, (err, template) ->
            expect(err?.message)              .not.exist
            expect(template.title)            .to.be.equal stackTemplateData.title
            expect(template.config)           .to.be.deep.equal stackTemplateData.config
            expect(template.credentials)      .to.be.equal stackTemplateData.credentials
            expect(template.machines.length)  .to.be.equal stackTemplateData.machines.length
            expect(template.accessLevel)      .to.be.equal stackTemplateData.accessLevel
            expect(template.template)         .to.exist
            expect(template.template.content) .to.be.equal stackTemplateData.template
            expect(template.template.details) .to.be.equal stackTemplateData.templateDetails
            expect(template.template.sum)     .to.exist
            done()


  describe '#some$()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to fetch stack templates', (done) ->

        withDummyClient ({ client }) ->

          StackTemplate.some$ client, {}, (err, template) ->
            expect(err?.message).to.be.equal 'Access denied'
            done()


    describe 'when user has the permission', ->

      it 'should be able to fetch stack template data', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplate     = null
          stackTemplateData = generateStackTemplateData client

          queue = [

            ->
              StackTemplate.create client, stackTemplateData, (err, template) ->
                expect(err?.message).to.not.exist
                stackTemplate = template
                queue.next()

            ->
              selector = { _id : stackTemplate._id }
              StackTemplate.some$ client, selector, (err, templates) ->
                expect(err?.message).to.not.exist
                expect(templates[0].title).to.be.equal stackTemplateData.title
                expect(templates[0].template.content).to.be.deep.equal stackTemplateData.template
                queue.next()

            -> done()

          ]

          daisy queue


  describe '#one$()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to fetch stack templates', (done) ->

        withDummyClient ({ client }) ->

          StackTemplate.one$ client, {}, {}, (err, template) ->
            expect(err?.message).to.be.equal 'Access denied'
            done()


    describe 'when user has the permission', ->

      it 'should be able to fetch stack template data', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplate     = null
          stackTemplateData = generateStackTemplateData client

          queue = [

            ->
              StackTemplate.create client, stackTemplateData, (err, template) ->
                expect(err).to.not.exist
                stackTemplate = template
                queue.next()

            ->
              selector = { '_id' : stackTemplate._id }
              StackTemplate.one$ client, selector, null, (err, template) ->
                expect(err?.message).to.not.exist
                expect(template).to.exist
                expect(template.title).to.be.equal stackTemplateData.title
                expect(template.template.content).to.be.deep.equal stackTemplateData.template
                queue.next()

            -> done()

          ]

          daisy queue


  describe 'delete()', ->

    describe 'when user doesnt have the permission', ->

      it 'should fail to delete the stack template', (done) ->

        stackTemplate = null

        queue = [

          ->
            withConvertedUser ({ client }) ->

              stackTemplateData = generateStackTemplateData client
              StackTemplate.create client, stackTemplateData, (err, template_) ->
                expect(err).to.not.exist
                stackTemplate = template_
                queue.next()

          ->
            withDummyClient ({ client }) ->

              stackTemplate.delete client, (err) ->
                expect(err?.message).to.be.equal 'Access denied'
                queue.next()

          -> done()

        ]

        daisy queue


    describe 'when user has the permission', ->

      it 'should be able to delete the stack template', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplate     = null
          stackTemplateData = null

          queue = [

            ->
              stackTemplateData = generateStackTemplateData client
              StackTemplate.create client, stackTemplateData, (err, template_) ->
                expect(err).to.not.exist
                stackTemplate = template_
                queue.next()

            ->
              stackTemplate.delete client, (err) ->
                expect(err).to.not.exist
                queue.next()

            ->
              StackTemplate.one { _id : stackTemplate._id }, (err, stackTemplate_) ->
                expect(err).to.not.exist
                expect(stackTemplate_).to.not.exist
                queue.next()

            -> done()

          ]

          daisy queue


  describe 'setAccess()', ->

    describe 'when user doesnt have the permission', ->

      it 'should fail to set access level of the template', (done) ->

        stackTemplate = null

        queue = [

          ->
            withConvertedUser ({ client }) ->

              stackTemplateData = generateStackTemplateData client
              StackTemplate.create client, stackTemplateData, (err, template_) ->
                expect(err).to.not.exist
                stackTemplate = template_
                queue.next()

          ->
            withDummyClient ({ client }) ->

              stackTemplate.setAccess client, 'public', (err) ->
                expect(err?.message).to.be.equal 'Access denied'
                queue.next()

          -> done()

        ]

        daisy queue


    describe 'when user has the permission', ->

      it 'should be able to set access level of stack template', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplate     = null
          stackTemplateData = null

          queue = [

            ->
              stackTemplateData = generateStackTemplateData client
              StackTemplate.create client, stackTemplateData, (err, template_) ->
                expect(err).to.not.exist
                stackTemplate = template_
                queue.next()

            ->
              stackTemplate.setAccess client, 'someInvalidAccessLevel', (err) ->
                expect(err?.message).to.be.equal 'Wrong level specified!'
                queue.next()

            ->
              stackTemplate.setAccess client, 'group', (err) ->
                expect(err).to.not.exist
                expect(stackTemplate.accessLevel).to.be.equal 'group'
                queue.next()

            ->
              stackTemplate.setAccess client, 'public', (err) ->
                expect(err).to.not.exist
                expect(stackTemplate.accessLevel).to.be.equal 'public'
                queue.next()

            -> done()

          ]

          daisy queue


  describe 'update$()', ->

    describe 'when user doesnt have the permission', ->

      it 'should fail to update the stack template', (done) ->

        stackTemplate = null

        queue = [

          ->
            withConvertedUser ({ client }) ->

              stackTemplateData = generateStackTemplateData client
              StackTemplate.create client, stackTemplateData, (err, template_) ->
                expect(err).to.not.exist
                stackTemplate = template_
                queue.next()

          ->
            withDummyClient ({ client }) ->

              stackTemplate.update$ client, {}, (err) ->
                expect(err?.message).to.be.equal 'Access denied'
                queue.next()

          -> done()

        ]

        daisy queue


    describe 'when user has the permission', ->

      it 'should be able to update the stack template', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplate     = null
          stackTemplateData = null

          queue = [

            ->
              stackTemplateData = generateStackTemplateData client
              StackTemplate.create client, stackTemplateData, (err, template_) ->
                expect(err).to.not.exist
                stackTemplate = template_
                queue.next()

            ->
              params = { title : 'title should be updated' }
              stackTemplate.update$ client, params, (err) ->
                expect(err).to.not.exist
                expect(stackTemplate.title).to.be.equal params.title
                queue.next()

            ->
              params = { group : 'group should be immutable' }
              stackTemplate.update$ client, params, (err) ->
                expect(err).to.exist
                queue.next()

            ->
              params = { originId : 'originId should be immutable' }
              stackTemplate.update$ client, params, (err) ->
                expect(err).to.exist
                queue.next()

            -> done()

          ]

          daisy queue


beforeTests()

runTests()

