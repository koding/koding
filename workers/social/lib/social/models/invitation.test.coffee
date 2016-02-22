JUser                         = require './user'
JGroup                        = require './group'
JAccount                      = require './account'
JSession                      = require './session'
JInvitation                   = require './invitation'
{ async
  expect
  withDummyClient
  generateDummyClient
  withConvertedUser
  generateRandomEmail
  generateRandomString
  checkBongoConnectivity
  generateDummyUserFormData } = require '../../../testhelper'


# making sure we have mongo connection before tests
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = ->

  describe 'workers.social.invitation.create', ->

    initialEmail  = null
    initialInvite = null

    describe 'if user is not a member yet', ->

      it 'should receive the invitation', (done) ->

        initialEmail = email = generateRandomEmail()

        withConvertedUser { createGroup: yes }, (data) ->
          { client: adminClient, userFormData: adminUserFormData } = data

          queue = [

            (next) ->
              # creating an invitation for the unregistered user
              invitationReq = { invitations:[ { email } ] }
              JInvitation.create adminClient, invitationReq, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              # expecting invitation to exist
              params = { email, groupName: adminClient.context.group }
              JInvitation.one params, (err, invitation) ->
                initialInvite = invitation
                expect(err).to.not.exist
                expect(invitation).to.exist
                next()

          ]

          async.series queue, done


    describe 'if user asks for the invite codes', ->

      it 'should receive the invitate codes', (done) ->

        email = generateRandomEmail()

        withConvertedUser { createGroup: yes }, (data) ->
          { client: adminClient, userFormData: adminUserFormData } = data

          # creating an invitation for the unregistered user
          invitationReq = { invitations:[ { email } ], returnCodes: yes }
          JInvitation.create adminClient, invitationReq, (err, res) ->
            expect(err).to.not.exist
            expect(res[0].email is email).to.be.true
            done()


    describe 'if already invited user forced a new invite', ->

      it 'should receive a new invitation', (done) ->

        email = initialEmail

        withConvertedUser { createGroup: yes }, (data) ->
          { client: adminClient, userFormData: adminUserFormData } = data

          queue = [

            (next) ->
              # creating an invitation for the unregistered user
              invitationReq = { invitations:[ { email } ], forceInvite: yes }
              JInvitation.create adminClient, invitationReq, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              # expecting invitation to exist
              params = { email, groupName: adminClient.context.group }
              JInvitation.one params, (err, invitation) ->
                expect(err).to.not.exist
                expect(invitation).to.exist
                expect(invitation.code isnt initialInvite.code).to.be.true
                next()

          ]

          async.series queue, done


    describe 'if user is already member', ->

      it 'should not receive the invitation', (done) ->

        registeredEmail = null

        # registering a user and creating a group
        withConvertedUser { createGroup: yes }, (data) ->
          { group, client: adminClient, userFormData: adminUserFormData } = data

          queue = [

            (next) ->
              # registering a user to the previously created group
              withConvertedUser { context: { group : group.slug } }, ({ userFormData }) ->
                registeredEmail = userFormData.email
                next()

            (next) ->
              # trying to create an invitation for the registered user's email
              invitationReq = { invitations:[ { email: registeredEmail } ] }
              JInvitation.create adminClient, invitationReq, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              # expecting invitation not to be created
              params = { email: registeredEmail, groupName: group.slug }
              JInvitation.one params, (err, invitation) ->
                expect(err).to.not.exist
                expect(invitation).to.not.exist
                next()

          ]

          async.series queue, done


beforeTests()

runTests()
