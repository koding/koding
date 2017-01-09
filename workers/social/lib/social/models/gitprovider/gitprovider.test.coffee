GitProvider = require './index'

{ expect
  withConvertedUser
  expectAccessDenied
  generateRandomString
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

          template   =
            content  :'''
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
          readme      =
            content   : 'This is awesome stack template!!!'

          user        = 'koding'
          repo        = generateRandomString()
          originalUrl = "https://github.com/#{user}/#{repo}"
          title       = 'Imported stack template'

          importData = { template, readme, originalUrl, user, repo }

          GitProvider.createImportedStackTemplate client, title, importData, (err, _template) ->
            expect(err?.message)                               .not.exist
            expect(_template.title)                            .to.be.equal title
            expect(_template.description)                      .to.be.equal readme.content
            expect(_template.config.requiredData)              .to.deep.equal { user: [ 'username' ], group: [ 'slug' ] }
            expect(_template.config.requiredProviders[0])      .to.equal 'aws'
            expect(_template.config.remoteDetails.originalUrl) .to.be.equal originalUrl
            expect(_template.template.rawContent)              .to.be.equal template.content
            done()


beforeTests()

runTests()
