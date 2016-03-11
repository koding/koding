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
  generateDummyUserFormData
  expectAccessDenied } = require '../../../testhelper'


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
          JInvitation.create adminClient, invitationReq, (err, [invite]) ->
            expect(err).to.not.exist
            expect(invite).to.exist
            expect(invite.email is email).to.be.true
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


  describe 'workers.social.invitation.some', ->

    it 'should fail if user does not have permission ', (done) ->

      expectAccessDenied JInvitation, 'some$', {}, {}, done


    it 'should have default group name if user is not an admin', (done) ->

      withConvertedUser { createGroup: yes }, (data) ->
        { client: adminClient } = data
        dummyGroupName = 'Foo'
        selector = { groupSlug: dummyGroupName }

        email = generateRandomEmail()
        invitationReq = { invitations:[ { email } ] }
        JInvitation.create adminClient, invitationReq, (err) ->
          JInvitation.some$ adminClient, selector, {}, (err, invitations) ->

            invitationGroupName = invitations[0].data.groupName
            expect(invitationGroupName).to.not.equal dummyGroupName
            expect(invitationGroupName).to.be.equal data.group.slug

            done()

    it 'should update groupSlug and fetch other group invitations', (done) ->

      groupSlug1   = null
      groupSlug2   = null
      adminClient1 = null
      adminClient2 = null
      adminAccount = null
      invitedUser1 = null
      invitedUser2 = null

      queue = [

        # create first group
        (next) ->
          withConvertedUser { createGroup: yes }, ({ client, group }) ->
            groupSlug1   = group.slug
            adminClient1 = client
            next()

        # invite a user to first group
        (next) ->
          email = invitedUser1 = generateRandomEmail()
          invitationReq = { invitations:[ { email } ] }
          JInvitation.create adminClient1, invitationReq, (err) ->
            expect(err).to.not.exist
            next()

        # create second group
        (next) ->
          options = { createGroup: yes, role: 'admin' }
          withConvertedUser options, ({ client, account, group }) ->
            groupSlug2   = group.slug
            adminClient2 = client
            adminAccount = account
            next()

        # invite a user to second group
        (next) ->
          email = invitedUser2 = generateRandomEmail()
          invitationReq = { invitations:[ { email } ] }
          JInvitation.create adminClient2, invitationReq, (err) ->
            expect(err).to.not.exist
            next()

        # add super-admin global flag to second converted account
        (next) ->
          adminAccount.update { $set: { globalFlags: [ 'super-admin' ] } }, next

        # try to hijack groupSlug with first group admin
        # returned result set should be for admin's own group
        (next) ->
          JInvitation.some$ adminClient1, { groupSlug: groupSlug2 }, {}, (err, invitations) ->
            expect(err).to.not.exist
            expect(invitations.length).to.above 0
            expect(invitations[0].data).to.exist
            expect(invitations[0].data.groupName).to.equal groupSlug1
            next()

      ]

      async.series queue, done


beforeTests()

runTests()
