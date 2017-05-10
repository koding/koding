ComputeProvider = require './computeprovider'
JStackTemplate = require './stacktemplate'
JCounter = require '../counter'

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

{ PROVIDERS } = require './computeutils'

{ slugify } = require '../../traits/slugifiable'

# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.stacktemplate', ->

  describe '#create()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to create stack template', (done) ->

        expectAccessDenied JStackTemplate, 'create', {}, done


    describe 'when user has the permission', ->

      it 'should be able to create stack template', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplateData = generateStackTemplateData client
          JStackTemplate.create client, stackTemplateData, (err, template) ->
            expect(err?.message)              .not.exist
            expect(template.title)            .to.be.equal stackTemplateData.title
            expect(template.slug)             .to.be.equal slugify stackTemplateData.title
            expect(template.config)           .to.exist
            expect(template.credentials)      .to.be.equal stackTemplateData.credentials
            expect(template.machines.length)  .to.be.equal stackTemplateData.machines.length
            expect(template.accessLevel)      .to.be.equal stackTemplateData.accessLevel
            expect(template.template)         .to.exist
            expect(template.template.content) .to.be.equal stackTemplateData.template
            expect(template.template.details) .to.be.equal stackTemplateData.templateDetails
            expect(template.template.sum)     .to.exist
            done()

      it 'should generate a title/slug if not provided', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplateData = generateStackTemplateData client

          delete stackTemplateData.slug
          delete stackTemplateData.title

          JStackTemplate.create client, stackTemplateData, (err, template) ->
            expect(err?.message)                  .not.exist
            expect(template.title)                .to.exist
            expect(template.title.split(' ')[-2..][0]).to.be.equal 'Aws'
            expect(template.slug)                 .to.be.equal slugify template.title
            done()

      it 'should generate config automatically from template content', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplateData = generateStackTemplateData client
          delete stackTemplateData.config

          JStackTemplate.create client, stackTemplateData, (err, template) ->
            expect(err?.message)                      .not.exist
            expect(template.config)                   .to.exist
            expect(template.config.groupStack)        .to.be.equal no
            expect(template.config.requiredData)      .to.be.deep.equal {
              user: [ 'username' ], group: [ 'slug' ]
            }
            expect(template.config.requiredProviders) .to.be.deep.equal ['aws']
            done()

      it 'should generate rawContent automatically from template content if not provided', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplateData = generateStackTemplateData client
          delete stackTemplateData.rawContent

          JStackTemplate.create client, stackTemplateData, (err, template) ->
            expect(err?.message)                      .not.exist
            expect(template.template.rawContent)      .to.exist
            expect(template.template.rawContent)      .to.be.deep.equal """
            provider:
              aws:
                access_key: '${var.aws_access_key}'
                secret_key: '${var.aws_secret_key}'
            resource:
              aws_instance:
                test_machine:
                  instance_type: t2.nano
                  ami: ''
                  tags:
                    Name: '${var.koding_user_username}-${var.koding_group_slug}'

            """
            done()

      it 'should fail to generate rawContent automatically from broken template content if not provided', (done) ->

        withConvertedUser ({ client }) ->

          stackTemplateData = generateStackTemplateData client
          delete stackTemplateData.rawContent
          stackTemplateData.template = 'broken json; {'

          JStackTemplate.create client, stackTemplateData, (err, template) ->
            expect(err)         .to.exist
            expect(err.message) .to.be.equal 'Failed to parse template'
            expect(err.error)   .to.be.equal 'Unexpected token b in JSON at position 0'
            done()


  describe '#some$()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to fetch stack templates', (done) ->

        expectAccessDenied JStackTemplate, 'some$', {}, done


    describe 'when user has the permission', ->

      it 'should be able to fetch stack template data', (done) ->

        withConvertedUserAndStackTemplate (data) ->
          { client, stackTemplate, stackTemplateData } = data
          selector = { _id : stackTemplate._id }

          JStackTemplate.some$ client, selector, (err, templates) ->
            expect(err?.message).to.not.exist
            expect(templates[0].title).to.be.equal stackTemplateData.title
            expect(templates[0].template.content).to.be.deep.equal stackTemplateData.template
            done()


  describe '#one$()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to fetch stack templates', (done) ->

        expectAccessDenied JStackTemplate, 'one$', {}, {}, done


    describe 'when user has the permission', ->

      it 'should be able to fetch stack template data', (done) ->

        withConvertedUserAndStackTemplate (data) ->
          { client, stackTemplate, stackTemplateData } = data
          selector = { _id : stackTemplate._id }

          JStackTemplate.one$ client, selector, null, (err, template) ->
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
              JStackTemplate.one { _id : stackTemplate._id }, (err, stackTemplate_) ->
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
              stackTemplate.generateStack client, {}, (err) ->
                expect(err.message).to.be.equal 'Stack is not verified yet'
                next()

            (next) ->
              config = { verified: yes }
              stackTemplate.update$ client, { config }, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              stackTemplate.generateStack client, {}, (err, res) ->
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


      it 'should keep limits as is if generating fails', (done) ->

        options       =
          machines    : generateStackMachineData 2
          createGroup : yes

        options.machines[0].provider = 'nosuchprovider'

        withConvertedUserAndStackTemplate options, ({ client, group, stackTemplate }) ->

          counterOptions =
            namespace : group.getAt 'slug'
            type      : ComputeProvider.COUNTER_TYPE.instances

          async.series [

            (next) ->
              JCounter.count counterOptions, (err, count) ->
                expect(err).to.not.exist
                expect(count).to.equal 0
                next()

            (next) ->
              stackTemplate.generateStack client, {}, (err) ->
                expect(err.message).to.be.equal 'Stack is not verified yet'
                next()

            (next) ->
              config = { verified: yes }
              stackTemplate.update$ client, { config }, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              stackTemplate.generateStack client, {}, (err, res) ->
                expect(err).to.not.exist
                expect(res.results.machines[0].err).to.exist
                expect(res.results.machines[0].obj).to.not.exist
                expect(res.results.machines[0].err.name).to.equal 'ProviderNotFound'
                next()

            (next) ->
              JCounter.count counterOptions, (err, count) ->
                expect(err).to.not.exist
                expect(count).to.equal 1
                next()

          ], done



    describe 'when team limit has been reached', ->

      it 'should fail to generate a stack from the template', (done) ->

        options       =
          machines    : generateStackMachineData 2
          createGroup : yes

        withConvertedUserAndStackTemplate options, ({ client, group, stackTemplate }) ->

          async.series [

            (next) ->
              group.update { $set: { 'config.testlimit': 'test' } }, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              ComputeProvider.updateGroupStackUsage group, 'increment', (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              config = { verified: yes }
              stackTemplate.update$ client, { config }, (err, template) ->
                expect(err).to.not.exist
                expect(template.config.verified).to.be.equal yes
                next()

            (next) ->
              stackTemplate.generateStack client, {}, (err, res) ->
                expect(err).to.exist
                expect(err.message).to.be.equal 'Provided limit has been reached'
                expect(res).to.not.exist
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

          { originId, group } = stackTemplate

          queue = [

            (next) ->
              params = { title : 'title should be updated' }
              stackTemplate.update$ client, params, (err) ->
                expect(err).to.not.exist
                expect(stackTemplate.title).to.be.equal params.title
                next()

            (next) ->
              params = { group : 'group should be immutable' }
              stackTemplate.update$ client, params, (err, stackTemplate) ->
                expect(err).to.not.exist
                expect(stackTemplate.group).to.be.equal group
                next()

            (next) ->
              params = { originId : 'originId should be immutable' }
              stackTemplate.update$ client, params, (err, stackTemplate) ->
                expect(err).to.not.exist
                expect(stackTemplate.originId).to.be.equal originId
                next()

          ]

          async.series queue, done


      it 'should be able to update a cloned stacktemplate', (done) ->

        withConvertedUserAndStackTemplate (data) ->
          { client, stackTemplate, stackTemplateData } = data

          stackTemplate.clone client, (err, clonedTemplate) ->
            expect(err).to.not.exist

            queue = [

              (next) ->
                params = { title: 'title should be updated' }
                clonedTemplate.update$ client, params, (err) ->
                  expect(err).to.not.exist
                  expect(clonedTemplate.title).to.be.equal params.title
                  next()

              (next) ->
                params = { template: '{}', rawContent: '--' }
                clonedTemplate.update$ client, params, (err, clonedTemplate) ->
                  expect(err)                                .to.not.exist
                  expect(clonedTemplate.template.content)    .to.be.equal params.template
                  expect(clonedTemplate.template.rawContent) .to.be.equal params.rawContent
                  expect(clonedTemplate.template.sum)        .to.be.equal 'bf21a9e8fbc5a3846fb05b4fa0859e0917b2202f' # sum of "{}"
                  next()

              (next) ->
                params = { config: { groupStack: yes } }
                clonedTemplate.update$ client, params, (err, clonedTemplate) ->
                  expect(err).to.not.exist
                  expect(clonedTemplate.config.groupStack)   .to.be.equal yes
                  # sum needs to stay same
                  expect(clonedTemplate.template.sum)        .to.be.equal 'bf21a9e8fbc5a3846fb05b4fa0859e0917b2202f'
                  next()

            ]

            async.series queue, done


  describe '#samples()', ->

    it 'should return sample templates for all stack supported providers', (done) ->

      withConvertedUser ({ client }) ->

        ComputeProvider.fetchProviders client, (err, providers) ->
          expect(err).to.not.exist

          queue = providers.map (provider) -> (next) ->

            JStackTemplate.samples client, { provider }, (err, sample) ->
              expect(err).to.not.exist
              expect(sample).to.exist
              expect(sample.yaml).to.exist
              expect(sample.json).to.exist
              expect(sample.defaults).to.exist
              next()

          async.series queue, done


  describe 'preview()', ->

    it 'should be able to generate preview for given stacktemplate content', (done) ->

      withConvertedUser ({ client }) ->

        { connection: { delegate } } = client
        { profile: { nickname } } = delegate

        JStackTemplate.preview client, {
          template: '''
            foo bar baz
            ${var.koding_user_username}
            ${var.custom_foo}
          '''
          custom:
            foo: 'bar'
        }, (err, data) ->
          expect(err)           .to.not.exist
          expect(data)          .to.exist
          expect(data.errors)   .to.be.deep.equal {}
          expect(data.warnings) .to.be.deep.equal {}
          expect(data.template) .to.be.equal """
            foo bar baz
            #{nickname}
            bar
          """
          done()

    it 'should generate warnings and errors for missing data', (done) ->

      withConvertedUser ({ client }) ->

        { connection: { delegate } } = client
        { profile: { nickname } } = delegate

        JStackTemplate.preview client, {
          template: '''
            ${var.userInput_test}
            foo bar baz
            ${var.koding_user_username}
            ${var.custom_foo}
            ${var.custom_baz}
          '''
          custom:
            foo: 'bar'
        }, (err, data) ->
          expect(err)           .to.not.exist
          expect(data)          .to.exist
          expect(data.errors)   .to.be.deep.equal {
            custom: ['baz']
          }
          expect(data.warnings) .to.be.deep.equal {
            userInput: ['test']
          }
          expect(data.template) .to.be.equal """
            ${var.userInput_test}
            foo bar baz
            #{nickname}
            bar
            ${var.custom_baz}
          """
          done()


  describe 'clone()', ->

    describe 'when user doesnt have the permission', ->

      it 'should fail to clone a stacktemplate', (done) ->

        withConvertedUserAndStackTemplate ({ stackTemplate }) ->
          expectAccessDenied stackTemplate, 'clone', done


    describe 'when user has the permission', ->

      it 'should be able to clone a stacktemplate', (done) ->

        withConvertedUserAndStackTemplate (data) ->
          { client, stackTemplate, stackTemplateData } = data

          stackTemplate.clone client, (err, clonedTemplate) ->
            expect(err)                              .to.not.exist
            expect(clonedTemplate)                   .to.exist
            expect(clonedTemplate.title)             .to.be.equal "#{stackTemplate.title} - clone"
            expect(clonedTemplate.config.clonedFrom) .to.be.equal stackTemplate._id
            expect(clonedTemplate.config.clonedSum)  .to.be.equal stackTemplate.template.sum
            done()


    describe 'should support different access levels', ->

      describe 'when accessLevel is private', ->

        it 'should deny cloning by other users in same group', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data
            groupSlug = client.context.group

            withConvertedUser { groupSlug }, (data) ->

              { client } = data
              stackTemplate.clone client, (err, clonedTemplate) ->
                expect(err).to.exist
                expect(clonedTemplate).to.not.exist
                done()

        it 'should deny cloning by other users in different groups', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data
            groupSlug = generateRandomString()

            withConvertedUser { groupSlug }, (data) ->

              { client } = data
              stackTemplate.clone client, (err, clonedTemplate) ->
                expect(err).to.exist
                expect(clonedTemplate).to.not.exist
                done()

        it 'should allow cloning by owner', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data

            stackTemplate.clone client, (err, clonedTemplate) ->
              expect(err)                              .to.not.exist
              expect(clonedTemplate)                   .to.exist
              expect(clonedTemplate.title)             .to.be.equal "#{stackTemplate.title} - clone"
              expect(clonedTemplate.config.clonedFrom) .to.be.equal stackTemplate._id
              expect(clonedTemplate.config.clonedSum)  .to.be.equal stackTemplate.template.sum
              done()


      describe 'when accessLevel is group', ->

        it 'should allow cloning by other users in same group', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data

            stackTemplate.setAccess client, 'group', (err) ->
              expect(err).to.not.exist

              groupSlug = client.context.group
              withConvertedUser { groupSlug }, (data) ->

                { client } = data

                stackTemplate.clone client, (err, clonedTemplate) ->
                  expect(err)                              .to.not.exist
                  expect(clonedTemplate)                   .to.exist
                  expect(clonedTemplate.title)             .to.be.equal "#{stackTemplate.title} - clone"
                  expect(clonedTemplate.config.clonedFrom) .to.be.equal stackTemplate._id
                  expect(clonedTemplate.config.clonedSum)  .to.be.equal stackTemplate.template.sum
                  done()

        it 'should deny cloning by other users in different groups', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data

            stackTemplate.setAccess client, 'group', (err) ->
              expect(err).to.not.exist

              groupSlug = generateRandomString()
              withConvertedUser { groupSlug }, (data) ->

                { client } = data

                stackTemplate.clone client, (err, clonedTemplate) ->
                  expect(err).to.exist
                  expect(clonedTemplate).to.not.exist
                  done()

        it 'should allow cloning by owner', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data

            stackTemplate.setAccess client, 'group', (err) ->
              expect(err).to.not.exist

              stackTemplate.clone client, (err, clonedTemplate) ->
                expect(err)                              .to.not.exist
                expect(clonedTemplate)                   .to.exist
                expect(clonedTemplate.title)             .to.be.equal "#{stackTemplate.title} - clone"
                expect(clonedTemplate.config.clonedFrom) .to.be.equal stackTemplate._id
                expect(clonedTemplate.config.clonedSum)  .to.be.equal stackTemplate.template.sum
                done()

      describe 'when accessLevel is public', ->

        it 'should allow cloning by other users in same group', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data

            stackTemplate.setAccess client, 'public', (err) ->
              expect(err).to.not.exist

              groupSlug = client.context.group
              withConvertedUser { groupSlug }, (data) ->

                { client } = data

                stackTemplate.clone client, (err, clonedTemplate) ->
                  expect(err)                              .to.not.exist
                  expect(clonedTemplate)                   .to.exist
                  expect(clonedTemplate.title)             .to.be.equal "#{stackTemplate.title} - clone"
                  expect(clonedTemplate.config.clonedFrom) .to.be.equal stackTemplate._id
                  expect(clonedTemplate.config.clonedSum)  .to.be.equal stackTemplate.template.sum
                  done()

        it 'should allow cloning by other users in different groups', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data

            stackTemplate.setAccess client, 'public', (err) ->
              expect(err).to.not.exist

              groupSlug = generateRandomString()
              withConvertedUser { groupSlug, createGroup: yes }, (data) ->

                { client } = data

                stackTemplate.clone client, (err, clonedTemplate) ->
                  expect(err)                              .to.not.exist
                  expect(clonedTemplate)                   .to.exist
                  expect(clonedTemplate.title)             .to.be.equal "#{stackTemplate.title} - clone"
                  expect(clonedTemplate.config.clonedFrom) .to.be.equal stackTemplate._id
                  expect(clonedTemplate.config.clonedSum)  .to.be.equal stackTemplate.template.sum
                  done()

        it 'should allow cloning by owner', (done) ->

          withConvertedUserAndStackTemplate (data) ->
            { client, stackTemplate } = data

            stackTemplate.setAccess client, 'public', (err) ->
              expect(err).to.not.exist

              stackTemplate.clone client, (err, clonedTemplate) ->
                expect(err)                              .to.not.exist
                expect(clonedTemplate)                   .to.exist
                expect(clonedTemplate.title)             .to.be.equal "#{stackTemplate.title} - clone"
                expect(clonedTemplate.config.clonedFrom) .to.be.equal stackTemplate._id
                expect(clonedTemplate.config.clonedSum)  .to.be.equal stackTemplate.template.sum
                done()


beforeTests()

runTests()
