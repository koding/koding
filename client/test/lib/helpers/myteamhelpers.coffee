helpers = require './helpers.js'
utils = require '../utils/utils.js'
teamsHelpers = require './teamshelpers.js'


module.exports =

  inviteUser: (browser, role) ->

    index = if role is 'member' then 2 else 1

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index
    successMessage = "Invitation is sent to #{userEmail}"

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

    return userEmail

  inviteTheUser: (browser, user, role) ->

    index = if role is 'member' then 2 else 1

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    emailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(#{index}) .kdinput.text.user-email"
   
    browser
      .waitForElementVisible invitationsModalSelector, 20000
      .waitForElementVisible emailInputSelector, 20000
      .scrollToElement invitationsModalSelector
      .scrollToElement invitationsModalSelector
      .setValue emailInputSelector, user.email

    successMessage = "Invitation is sent to #{user.email}"

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

  inviteAll: (browser) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'

    newEmailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(4) .kdinput.text.user-email"
    newUserEmail = "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"

    successMessage = 'All invitations are sent.'

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    firstUserEmail = @fillInviteInputByIndex browser, 1
    secondUserEmail = @fillInviteInputByIndex browser, 2
    thirdUserEmail = @fillInviteInputByIndex browser, 3

    browser
      .pause 3000
      .waitForElementVisible newEmailInputSelector, 10000
      .setValue newEmailInputSelector, newUserEmail
      .pause 5000
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

  uploadCSV: (browser) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    uploadCSVButtonSelector = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.ft"
    message = 'Coming Soon!'

    browser
      .waitForElementVisible invitationsModalSelector, 20000
      .click uploadCSVButtonSelector
    @assertConfirmation browser, message


  resendInvitation: (browser, role) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'

    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    index = if role is 'member' then 2 else 1

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index
    successMessage = "Invitation is sent to #{userEmail}"

    browser
      .pause 2000
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton
    @acceptConfirmModal browser if role is 'admin'
    @assertConfirmation browser, successMessage
    browser
      .pause 10000

    userEmail = @fillInviteInputByIndex browser, index, userEmail
    successMessage = "Invitation is resent to #{userEmail}"

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser

    if role is 'admin'
      browser
        .pause 2000
      @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

    return userEmail


  newInviteFromResendModal: (browser, role) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    userEmail = @inviteUser browser, role
    index = if role is 'member' then 2 else 1
    browser
      .pause 5000
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index, userEmail
    newEmail = @fillInviteInputByIndex browser, index + 1
    successMessage = "Invitation is sent to #{newEmail}"

    browser
      .click sendInvitesButton
    @acceptConfirmModal browser  if role is 'admin'
    @rejectConfirmModal browser
    @assertConfirmation browser, successMessage


  rejectConfirmModal: (browser) ->

    confirmModal = '.kdmodal.admin-invite-confirm-modal.kddraggable'
    cancelButton = '.kdmodal-content .kdbutton.solid.medium:nth-of-type(2)'
    browser
      .element 'css selector', confirmModal, (result) ->

        if result.status is 0
          browser
            .pause 2000
            .waitForElementVisible cancelButton, 10000
            .click                 cancelButton


  acceptConfirmModal: (browser) ->

    confirmModal = '.kdmodal.admin-invite-confirm-modal.kddraggable'
    confirmButton = '.kdmodal-content .kdbutton.confirm.solid.green.medium.w-loader'

    browser
      .element 'css selector', confirmModal, (result) ->

        if result.status is 0
          browser
            .pause 2000
            .waitForElementVisible confirmButton, 10000
            .click                 confirmButton


  assertConfirmation: (browser, successMessage) ->

    browser
      .waitForElementVisible '.kdnotification', 10000
      .assert.containsText '.kdnotification', successMessage
      .pause 2000


  fillInviteInputByIndex: (browser, index, userEmail = null) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    emailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(#{index}) .kdinput.text.user-email"
    userEmail ?= "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"

    browser
      .waitForElementVisible emailInputSelector, 20000
      .setValue emailInputSelector, userEmail

    return userEmail


  logoutTeam: (browser, callback) ->
  
    browser
      .click '#main-sidebar'
      .waitForElementVisible '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name', 20000
      .click '#kdmaincontainer.with-sidebar #main-sidebar .logo-wrapper .team-name'
      .waitForElementVisible '.SidebarMenu.kdcontextmenu .kdlistview-contextmenu.default', 20000
      .waitForElementVisible '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default',2000
      .click '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default:nth-of-type(4)'
              
      .pause 2000, -> callback()


  inviteUsers: (browser, invitations, callback) ->

    fn = ( invitations, done ) ->
      _remote.api.JInvitation.create { invitations: invitations }, (err) ->
        done err

    browser
      .timeoutsAsyncScript 10000
      .executeAsync  fn, [ invitations ], (result) ->
        callback()

  acceptAndJoinInvitation: (host, browser, user, callback) ->

    fn = ( email, done ) ->
      _remote.api.JInvitation.some { 'email': email }, {}, (err, invitations) ->
        if invitations.length
          invitation = invitations[0]
          done invitation.code
        else
          done()

    browser
      .timeoutsAsyncScript 10000
      .executeAsync fn, [user.email], (result) =>

        { status, value } = result

        if status is 0 and value
          browser.waitForElementVisible '.HomeAppView', 20000, yes, =>
            @logoutTeam browser, =>
              teamUrl       = helpers.getUrl yes
              invitationUrl = "#{teamUrl}/Invitation/#{result.value}"
              browser.url invitationUrl, =>
                teamsHelpers.fillJoinForm browser, user, yes, =>
                  browser.waitForElementVisible '.HomeAppView', 20000, yes, =>
                    @logoutTeam browser, (res) ->
                      teamsHelpers.loginToTeam browser, host, no, ->
                        callback res
        else
          callback('alreadyMember')

  checkTeammates: (browser, invitation, actionSelector1, actionSelector2, roleSelector, revoke = no, callback) ->

    unless invitation.accepted
      if revoke
        browser
          .pause 1000
          .click actionSelector2
          .pause 5000, -> callback()
      else
        browser
          .pause 1000
          .click actionSelector1
          .waitForElementVisible '.kdnotification.main', 20000
          .assert.containsText '.kdnotification.main', 'Invitation is resent.'
          .pause 1000, -> callback()
    else
      switch invitation.accepted
        when 'Member', 'Admin'
          browser
            .pause 1000
            .click actionSelector2
            .pause 1000
            .click roleSelector
            .pause 1000
            .click actionSelector2
            .pause 1000
            .waitForElementVisible roleSelector, 20000
            .assert.containsText roleSelector, invitation.accepted
            .pause 1000, -> callback()
        when 'Owner'
          browser
            .pause 1000
            .click 'body .ListView-row'
            .waitForElementVisible roleSelector, 20000
            .assert.containsText roleSelector, invitation.accepted
            .pause 1000, -> callback()
