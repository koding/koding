StackTemplate   = require './stacktemplate'

{ async
  expect
  withDummyClient
  withConvertedUser
  expectAccessDenied
  generateRandomString
  checkBongoConnectivity }    = require '../../../../testhelper'

{ generateStackMachineData
  generateStackTemplateData
  withConvertedUserAndStackTemplate } = require \
  '../../../../testhelper/models/computeproviders/stacktemplatehelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.stacktemplate', ->

  describe '#create()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to create stack template', (done) ->

        expectAccessDenied StackTemplate, 'create', {}, done


    describe 'when user has the permission', ->

      it 'should be able to create stack template', (done) ->

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

        expectAccessDenied StackTemplate, 'some$', {}, done


    describe 'when user has the permission', ->

      it 'should be able to fetch stack template data', (done) ->

        withConvertedUserAndStackTemplate (data) ->
          { client, stackTemplate, stackTemplateData } = data
          selector = { _id : stackTemplate._id }

          StackTemplate.some$ client, selector, (err, templates) ->
            expect(err?.message).to.not.exist
            expect(templates[0].title).to.be.equal stackTemplateData.title
            expect(templates[0].template.content).to.be.deep.equal stackTemplateData.template
            done()


  describe '#one$()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to fetch stack templates', (done) ->

        expectAccessDenied StackTemplate, 'one$', {}, {}, done


    describe 'when user has the permission', ->

      it 'should be able to fetch stack template data', (done) ->

        withConvertedUserAndStackTemplate (data) ->
          { client, stackTemplate, stackTemplateData } = data
          selector = { _id : stackTemplate._id }

          StackTemplate.one$ client, selector, null, (err, template) ->
            expect(err?.message).to.not.exist
            expect(template.title).to.be.equal stackTemplateData.title
            expect(template.template.content).to.be.deep.equal stackTemplateData.template
            done()


  describe 'delete()', ->

    describe 'when user doesnt have the permission', ->

      it 'should fail to delete the stack template', (done) ->

        withConvertedUserAndStackTemplate ({ stackTemplate }) ->
          expectAccessDenied stackTemplate, 'delete', done


    describe 'when user has the permission', ->

      it 'should be able to delete the stack template', (done) ->

        withConvertedUserAndStackTemplate ({ client, stackTemplate }) ->

          queue = [

            (next) ->
              stackTemplate.delete client, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              StackTemplate.one { _id : stackTemplate._id }, (err, stackTemplate_) ->
                expect(err).to.not.exist
                expect(stackTemplate_).to.not.exist
                next()

          ]

          async.series queue, done


  describe 'setAccess()', ->

    describe 'when user doesnt have the permission', ->

      it 'should fail to set access level of the template', (done) ->

        withConvertedUserAndStackTemplate ({ stackTemplate }) ->
          expectAccessDenied stackTemplate, 'setAccess', 'public', done


    describe 'when user has the permission', ->

      it 'should be able to set access level of stack template', (done) ->

        withConvertedUserAndStackTemplate ({ client, stackTemplate }) ->

          queue = [

            (next) ->
              stackTemplate.setAccess client, 'someInvalidAccessLevel', (err) ->
                expect(err?.message).to.be.equal 'Wrong level specified!'
                next()

            (next) ->
              stackTemplate.setAccess client, 'group', (err) ->
                expect(err).to.not.exist
                expect(stackTemplate.accessLevel).to.be.equal 'group'
                next()

            (next) ->
              stackTemplate.setAccess client, 'public', (err) ->
                expect(err).to.not.exist
                expect(stackTemplate.accessLevel).to.be.equal 'public'
                next()

          ]

          async.series queue, done


  describe 'generateStack()', ->

    describe 'when user doesnt have the permission', ->

      it 'should fail to generate stack from the template', (done) ->

        withConvertedUserAndStackTemplate ({ stackTemplate }) ->
          expectAccessDenied stackTemplate, 'generateStack', done


    describe 'when user has the permission', ->

      it 'should be able to generate a stack from the template', (done) ->

        options       =
          machines    : generateStackMachineData 2
          createGroup : yes

        withConvertedUserAndStackTemplate options, ({ client, stackTemplate }) ->

          async.series [

            (next) ->
              stackTemplate.generateStack client, (err) ->
                expect(err.message).to.be.equal 'Stack is not verified yet'
                next()

            (next) ->
              config = { verified: yes }
              stackTemplate.update$ client, { config }, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              stackTemplate.generateStack client, (err, res) ->
                expect(err).to.not.exist

                { stack, results: { machines } } = res

                expect(machines).to.exist
                expect(machines).to.have.length 2

                machines.forEach ({ err, obj: machine }, index) ->
                  expect(err).to.not.exist
                  expect(machine).to.exist
                  expect(machine.label).to.be.equal options.machines[index].label
                  expect(machine.generatedFrom).to.exist
                  expect(machine.generatedFrom.templateId).to.be.equal stackTemplate._id
                  expect(machine.generatedFrom.revision).to.be.equal stackTemplate.template.sum

                expect(stack).to.exist
                expect(stack.machines).to.have.length 2
                expect(stack.baseStackId).to.be.equal stackTemplate._id
                expect(stack.stackRevision).to.be.equal stackTemplate.template.sum

                next()

          ], done


  describe 'update$()', ->

    describe 'when user doesnt have the permission', ->

      it 'should fail to update the stack template', (done) ->

        withConvertedUserAndStackTemplate ({ stackTemplate }) ->
          expectAccessDenied stackTemplate, 'update$', {}, done


    describe 'when user has the permission', ->

      it 'should be able to update the stack template', (done) ->

        withConvertedUserAndStackTemplate (data) ->
          { client, stackTemplate, stackTemplateData } = data

          queue = [

            (next) ->
              params = { title : 'title should be updated' }
              stackTemplate.update$ client, params, (err) ->
                expect(err).to.not.exist
                expect(stackTemplate.title).to.be.equal params.title
                next()

            # FIXME: ~GG
            # (next) ->
            #   params = { group : 'group should be immutable' }
            #   stackTemplate.update$ client, params, (err) ->
            #     expect(err).to.exist
            #     next()

            # (next) ->
            #   params = { originId : 'originId should be immutable' }
            #   stackTemplate.update$ client, params, (err) ->
            #     expect(err).to.exist
            #     next()

          ]

          async.series queue, done


beforeTests()

runTests()
