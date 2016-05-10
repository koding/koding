GitProvider = require './index'

{ expect
  withConvertedUser
  expectAccessDenied
  checkBongoConnectivity } = require '../../../../testhelper'


beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = -> describe 'workers.social.models.gitprovider', ->

  describe '#createImportedStackTemplate()', ->

    describe 'when user doesnt have permission', ->

      it 'should fail to create imported stack template', (done) ->

        expectAccessDenied GitProvider, 'createImportedStackTemplate', {}, done


    describe 'when user has the permission', ->

      it 'should be able to create imported stack template', (done) ->

        withConvertedUser { createGroup : yes }, ({ client }) ->

          rawContent  = '''
              provider:
                aws:
                  access_key: '${var.aws_access_key}'
                  secret_key: '${var.aws_secret_key}'
              resource:
                aws_instance:
                  example_1:
                    instance_type: t2.nano
                    ami: ''
                    tags:
                      Name: '${var.koding_user_username}-${var.koding_group_slug}'
            '''
          description = 'This is awesome stack template!!!'
          originalUrl = 'https://github.com/koding/test'
          title       = 'Imported stack template'

          importData = { rawContent, description, originalUrl }

          GitProvider.createImportedStackTemplate client, title, importData, (err, template) ->
            expect(err?.message)                          .not.exist
            expect(template.title)                        .to.be.equal title
            expect(template.description)                  .to.be.equal description
            expect(template.config.requiredData)          .to.deep.equal { user: [ 'username' ], group: [ 'slug' ] }
            expect(template.config.requiredProviders[0])  .to.equal 'aws'
            expect(template.config.requiredProviders[1])  .to.equal 'koding'
            expect(template.config.importData.originalUrl).to.be.equal originalUrl
            expect(template.template.rawContent)          .to.be.equal rawContent
            done()


beforeTests()

runTests()
