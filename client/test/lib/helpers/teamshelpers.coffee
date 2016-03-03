helpers  = require '../helpers/helpers.js'
utils    = require '../utils/utils.js'
HUBSPOT  = no


teamsModalSelector       = '.TeamsModal--groupCreation'
companyNameSelector      = '.login-form input[testpath=company-name]'
sidebarSectionsSelector  = '.activity-sidebar .SidebarChannelsSection'
chatItem                 = '.Pane-body .ChatList .ChatItem'
chatInputSelector        = '.ChatPaneFooter .ChatInputWidget textarea'
invitationsModalSelector = ".kdmodal-content  .AppModal--admin-tabs .invitations"
pendingMembersTab        = "#{invitationsModalSelector} .kdtabhandle.pending-invitations"
pendingMemberView        = "#{invitationsModalSelector} .kdlistitemview-member.pending"


module.exports =


  openTeamsPage: (browser) ->

    teamsSelector = '[testpath=main-header] .full-menu a.teams'

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  teamsSelector, 20000
      .click                  teamsSelector
      .waitForElementVisible  '.content-page.teams', 20000


  fillSignUpFormOnTeamsHomePage: (browser, user) ->

    emailSelector  = '.login-form input[testpath=register-form-email]'
    buttonSelector = 'button[testpath=signup-company-button]'

    browser
      .waitForElementVisible  emailSelector, 20000
      .setValue               emailSelector, user.email
      .waitForElementVisible  companyNameSelector, 20000
      .setValue               companyNameSelector, user.name
      .waitForElementVisible  buttonSelector, 20000
      .click                  buttonSelector
      .pause                  2000 # wait for modal change


  enterTeamURL: (browser) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  '.TeamsModal--domain', 20000
      .waitForElementVisible  'input[name=slug]', 20000
      .click                  'button[testpath=domain-button]'
      .pause                  2000 # wait for modal change


  enterEmailDomains: (browser) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'input[type=checkbox]', 20000
      .waitForElementVisible  'input[name=domains]', 20000
      .click                  'button[testpath=allowed-domain-button]'
      .pause                  2000 # wait for modal change


  enterInvites: (browser) ->

    inviteeEmail = "inviteuser#{Date.now()}@kd.io"

    browser
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'input[name=invitee1]', 20000
      .setValue               'input[name=invitee1]', inviteeEmail
      .waitForElementVisible  'button[testpath=invite-button]', 2000
      .click                  'button[testpath=invite-button]'
      .pause                  2000 # wait for modal change


  fillUsernamePasswordForm: (browser, user) ->

    browser
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'input[name=username]', 20000
      .clearValue             'input[name=username]'
      .setValue               'input[name=username]', user.username
      .setValue               'input[name=password]', user.password
      .click                  '[testpath=register-button]'
      .pause                  2000 # wait for modal change

    @loginAssertion(browser)


  loginAssertion: (browser) ->

    user = utils.getUser()

    browser
      .waitForElementVisible  '.content-page.welcome', 20000 # Assertion
      .waitForElementVisible  '[testpath=main-sidebar]', 20000 # Assertion

    console.log " ✔ Successfully logged in with username: #{user.username} and password: #{user.password} to team: #{helpers.getUrl(yes)}"


  setupStackPage: (browser) ->

    browser
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'button.TeamsModal-button--green', 20000
      .click                  'button.TeamsModal-button--green'
      .pause                  2000 # wait for modal change


  congratulationsPage: (browser) ->

     browser
      .waitForElementVisible  teamsModalSelector, 20000
      .waitForElementVisible  'button span.button-title', 20000
      .click                  'button span.button-title'
      .pause                  2000 # wait for modal change


  loginToTeam: (browser, user) ->

    browser
      .pause                  2000 # wait for login page
      .waitForElementVisible  '.TeamsModal--login', 20000
      .waitForElementVisible  'form.login-form', 20000
      .setValue               'input[name=username]', user.username
      .setValue               'input[name=password]', user.password
      .click                  'button[testpath=login-button]'

    @loginAssertion(browser)


  loginTeam: (browser) ->

    user = utils.getUser()
    url  = helpers.getUrl(yes)

    teamsLogin = '.TeamsModal--login'

    browser.url url
    browser.maximizeWindow()

    browser.pause  3000
    browser.element 'css selector', teamsLogin, (result) =>
      if result.status is 0
        @loginToTeam browser, user
      else
        @createTeam browser

    return user


  createTeam: (browser, user, callback) ->

    modalSelector       = '.TeamsModal.TeamsModal--create'
    emailSelector       = "#{modalSelector} input[name=email]"
    companyNameSelector = "#{modalSelector} input[name=companyName]"
    signUpButton        = "#{modalSelector} button[type=submit]"
    user                = utils.getUser()

    invitationLink = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"

    browser
      .url                   invitationLink
      .waitForElementVisible modalSelector, 20000
      .waitForElementVisible emailSelector, 20000
      .waitForElementVisible companyNameSelector, 20000
      .clearValue            emailSelector
      .setValue              emailSelector, user.email
      .pause                 2000
      .setValue              companyNameSelector, user.teamSlug
      .click                 signUpButton
      .pause                 2500

    @enterTeamURL(browser)
    @fillUsernamePasswordForm(browser, user)


  createInvitation: (browser, user, callback) ->

    adminLink      = '.avatararea-popup a[href="/Admin"]'
    inviteLink     = '.invite-teams.AppModal-navItem'
    teamInvitePage = '.TeamInvite'
    inviteButton   = "#{teamInvitePage} button"
    sendMailPage   = "#{teamInvitePage} .kdscrollview"
    sendMailButton = "#{teamInvitePage} button.green:not(.hidden)"
    notification   = '.kdnotification.main'

    helpers.openAvatarAreaModal(browser)
    browser
      .waitForElementVisible  adminLink, 20000
      .click                  adminLink
      .waitForElementVisible  inviteLink, 20000
      .click                  inviteLink
      .waitForElementVisible  teamInvitePage, 20000
      .setValue               "#{teamInvitePage} textarea.text", user.email
      .waitForElementVisible  inviteButton, 20000
      .click                  inviteButton
      .waitForElementVisible  sendMailPage, 20000
      .assert.containsText    sendMailPage, user.email # Assertion
      .waitForElementVisible  sendMailButton, 20000
      .click                  sendMailButton
      .waitForElementVisible  notification, 20000
      .assert.containsText    notification, 'Invitations sent!'
      .pause                  2000
      .getAttribute           "#{sendMailPage} a" , 'href', (result) ->
        callback result.value


  openTeamSettingsModal: (browser) ->

    avatarareaPopup  = '.avatararea-popup.team'
    teamDashboard    = '.AppModal--admin'
    teamSettingsLink = "#{avatarareaPopup} .admin a"

    browser
      .waitForElementVisible  avatarareaPopup, 20000
      .waitForElementVisible  teamSettingsLink, 20000
      .click                  teamSettingsLink
      .waitForElementVisible  teamDashboard, 20000 # Assertion
      .pause                  200 # Wait for team settings
      .assert.containsText    teamDashboard, 'Team Settings' # Assertion


  clickTeamSettings: (browser) ->

    helpers.openAvatarAreaModal(browser, yes)
    @openTeamSettingsModal(browser)


  startStackCreate: (browser) ->

    welcomePageSelector = '.content-page.welcome'
    stackSelector       = 'ul.boxes a[testpath="configure-stack-button"]'
    overlaySelector     = '.AppModal--admin'
    getstartedSelector  = "#{overlaySelector} .stack-onboarding.get-started"
    buttonSelector      = "#{getstartedSelector} .header button"

    browser
      .waitForElementVisible  welcomePageSelector, 20000
      .waitForElementVisible  stackSelector, 20000
      .click                  stackSelector
      .waitForElementVisible  overlaySelector, 20000
      .waitForElementVisible  getstartedSelector, 20000
      .waitForElementVisible  buttonSelector, 20000
      .click                  buttonSelector


  openInvitationsTab: (browser) ->

    tabsSelector              = ".kdmodal-content .kdtabhandle-tabs"
    invitationsButtonSelector = "#{tabsSelector} .invitations"
    invitationsPageSelector   = ".kdmodal-content  .AppModal--admin-tabs .invitations"

    browser
      .waitForElementVisible  tabsSelector, 20000
      .waitForElementVisible  "#{tabsSelector} .invitations", 20000
      .waitForElementVisible  invitationsButtonSelector, 20000
      .click                  invitationsButtonSelector
      .waitForElementVisible  invitationsPageSelector, 20000 # Assertion
      .pause                  2000 # wait for page load


  moveToSidebarHeader: (browser, plus, channelHeader) ->

    sidebarSectionsHeaderSelector = "#{sidebarSectionsSelector} .SidebarSection-header"
    channelPlusSelector           = "#{sidebarSectionsHeaderSelector} a[href='/NewChannel']"

    browser
      .pause                   7500 # wait for load to sidebar
      .waitForElementVisible   sidebarSectionsSelector, 20000
      .moveToElement           sidebarSectionsHeaderSelector, 100, 7

    if plus
      browser
        .moveToElement          channelPlusSelector, 8, 5
        .waitForElementVisible  channelPlusSelector, 20000
        .click                  channelPlusSelector
    else if channelHeader
      browser
        .click                  sidebarSectionsHeaderSelector


  createChannel: (browser, user, channelName, isInvalid, purpose) ->

    channelModalSelector             = '.CreateChannel-Modal .CreateChannel-content'
    createChannelModalNameSelector   = "#{channelModalSelector} .channelName input"
    purposeSelector                  = "#{channelModalSelector} .channelPurpose input"
    createChannelModalButtonSelector = '.CreateChannel-Modal .Modal-buttons .Button--danger'
    channelName                    or= helpers.getFakeText().split(' ')[0] + Date.now()
    channelName                      = channelName.substring(0, 19)
    channelLinkOnSidebarSelector     = "#{sidebarSectionsSelector} a[href='/Channels/#{channelName}']"

    @moveToSidebarHeader(browser, yes)

    browser
      .waitForElementVisible  '.CreateChannel-Modal', 20000
      .waitForElementVisible  createChannelModalNameSelector, 20000
      .setValue               createChannelModalNameSelector, channelName

    if purpose
      browser
        .waitForElementVisible  purposeSelector, 20000
        .setValue               purposeSelector, purpose

    browser
      .waitForElementVisible  createChannelModalButtonSelector, 20000
      .moveToElement          createChannelModalButtonSelector, 32, 12
      .click                  createChannelModalButtonSelector

    if isInvalid
      browser
        .waitForElementVisible  '.channelName.invalid', 20000
        .pause                   2000
        .waitForElementVisible  '.CreateChannel-Modal', 20000
    else
      browser
        .pause                  3000 # wait for page load
        .waitForElementVisible  chatItem, 20000
        .pause                  3000
        .assert.containsText    chatItem, user.username
        .waitForElementVisible  sidebarSectionsSelector, 20000
        .pause                  2000 # wait for side bar channel list
        .waitForElementVisible  channelLinkOnSidebarSelector, 20000
        .assert.containsText    sidebarSectionsSelector, channelName

    if purpose
      browser.assert.containsText '.ChannelThreadPane-purposeWrapper .ChannelThreadPane-purpose',purpose

    return channelName


  sendComment: (browser, message, messageType) ->

    chatInputSelector     = '.ChatPaneFooter .ChatInputWidget textarea'
    imageSelector         = '.EmbedBox-container .EmbedBoxImage'
    imageTextSelector     = '.Pane-body .ChatList .ChatItem .ChatItem-contentBody:nth-of-type(1)'
    linkTextSelector      = '.EmbedBoxLinkContent .EmbedBoxLinkContent-description'
    emojiSelector         = '.ChatList .ChatItem .SimpleChatListItem .ChatListItem-itemBodyContainer .ChatItem-contentBody '
    blockSelector         = '.Pane-body .ChatList .ChatItem .ChatListItem-itemBodyContainer .ChatItem-contentBody .MessageBody blockquote'
    emojiSmileySelector   = "#{emojiSelector} .emoji-smiley"
    emojiThumbsUpSelector = "#{emojiSelector} .emoji-thumbsup"
    messageWithShortCode  = "console.log('123456789')"
    textAreaSelector      = '.Pane-body .ChatList'

    browser
      .waitForElementVisible  chatItem, 20000
      .waitForElementVisible  chatInputSelector, 20000
      .setValue               chatInputSelector, message + '\n'
      .waitForElementVisible  chatItem, 20000

    if not messageType
      browser
        .assert.containsText      textAreaSelector, message

    switch messageType
      when 'messageWithCode'
        browser
          .pause                  3000
          .assert.containsText    "#{textAreaSelector} .ChatItem .SimpleChatListItem", messageWithShortCode
      when 'messageWithImage'
        browser
          .waitForElementVisible  imageSelector, 20000
          .assert.containsText    imageTextSelector, message
      when 'messageWithLink'
        browser
          .waitForElementVisible  linkTextSelector, 20000
          .assert.containsText    linkTextSelector, 'The Free Encyclopedia'
      when 'messageWithEmoji'
        browser
          .waitForElementVisible  emojiSmileySelector, 20000
          .waitForElementVisible  emojiSmileySelector, 20000
          .pause                  2000
          .waitForElementVisible  emojiThumbsUpSelector, 20000
      when 'messageWithBlockquote'
        browser
          .pause                  3000
          .waitForElementVisible  blockSelector, 20000
          .assert.containsText    blockSelector, 'Message with blockquote'


  createChannelsAndCheckList: (browser, user) ->

    channelHeader     = "#{sidebarSectionsSelector} .SidebarSection-header"
    channelListModal  = '.ChannelList-Modal'
    activeTabSelector = "#{channelListModal} .ChannelList-tab.active-tab"
    listItemSelector  = "#{channelListModal} .ChannelListItem"
    threadsContainer  = "#{channelListModal} .SidebarModalThreads"

    channelName1 = @createChannel(browser, user)
    channelName2 = @createChannel(browser, user)
    channelName3 = @createChannel(browser, user)

    browser
      .waitForElementVisible  sidebarSectionsSelector, 20000
      .waitForElementVisible  channelHeader, 20000
      .click                  channelHeader
      .waitForElementVisible  channelListModal, 20000
      .waitForElementVisible  activeTabSelector, 20000
      .assert.containsText    activeTabSelector, 'Your Channels'
      .waitForElementVisible  listItemSelector, 20000
      .assert.containsText    threadsContainer, channelName1
      .assert.containsText    threadsContainer, channelName2
      .assert.containsText    threadsContainer, channelName3

    return [ channelName1, channelName2, channelName3 ]


  leaveChannel: (browser) ->

    channelHeaderPaneSelector = '.ChannelThreadPane-content .ChannelThreadPane-header'
    buttonSelector            = "#{channelHeaderPaneSelector} .ButtonWithMenuWrapper"
    channelActionsSelector    = '.ButtonWithMenuItemsList.ChannelThreadPane-menuItems'
    leaveChannelSelector      = "#{channelActionsSelector} li:nth-child(2)"
    followChannelBox          = '.ChannelThreadPane-body .FollowChannelBox'

    browser
      .waitForElementVisible     channelHeaderPaneSelector, 20000
      .waitForElementVisible     buttonSelector, 20000
      .click                     buttonSelector
      .waitForElementVisible     channelActionsSelector, 20000
      .moveToElement             leaveChannelSelector, 70, 12
      .waitForElementVisible     leaveChannelSelector, 20000
      .click                     leaveChannelSelector
      .waitForElementVisible     followChannelBox, 20000 # Assertion
      .waitForElementNotVisible  chatInputSelector, 20000 # Assertion


  joinChannel: (browser) ->

    followChannelBox    = '.FollowChannelBox'
    followChannelButton = "#{followChannelBox} .Button-followChannel"

    @leaveChannel(browser)

    browser
      .waitForElementVisible     followChannelButton, 20000
      .click                     followChannelButton
      .waitForElementNotVisible  followChannelButton, 20000


  inviteUser: (browser, addMoreUser = no) ->

    invitationsModalSelector = ".kdmodal-content  .AppModal--admin-tabs .invitations"
    inviteUserView           = "#{invitationsModalSelector} .invite-view"
    emailInputSelector       = "#{inviteUserView} .invite-inputs input.user-email"
    userEmail                = "#{helpers.getFakeText().split(' ')[0]}@kd.io"
    inviteMemberButton       = "#{invitationsModalSelector} button.invite-members"
    confirmModal             = '.admin-invite-confirm-modal'
    confirmButton            = "#{confirmModal} button.confirm"
    notificationView         = '.kdnotification'

    browser
      .waitForElementVisible  inviteUserView, 20000
      .waitForElementVisible  emailInputSelector, 20000
      .setValue               emailInputSelector, userEmail
      .waitForElementVisible  inviteMemberButton, 20000
      .click                  inviteMemberButton

    browser.pause  2000 # wait for modal
    browser.element 'css selector', confirmModal, (result) ->
      if result.status is 0
        browser
          .waitForElementVisible confirmButton, 20000
          .click                 confirmButton

      successMessage = if addMoreUser
      then "Invitation is sent to"
      else "Invitation is sent to #{userEmail}"

      browser
        .waitForElementVisible  notificationView, 20000
        .assert.containsText    notificationView, successMessage
        .pause                  2000 # wait for notification

      if addMoreUser
        browser
          .waitForElementVisible  emailInputSelector, 20000
      else
        browser
          .click                  pendingMembersTab
          .waitForElementVisible  pendingMemberView, 20000
          .assert.containsText    pendingMemberView, userEmail

    return userEmail


  clickPendingInvitations: (browser, openTab = yes) ->

    if openTab
      @clickTeamSettings(browser)
      @openInvitationsTab(browser)

    browser
      .waitForElementVisible  pendingMembersTab, 20000
      .click                  pendingMembersTab
      .waitForElementVisible  pendingMemberView, 20000 # Assertion


  invitationAction: (browser, userEmail, revoke) ->

    pendingMemberView         = "#{invitationsModalSelector} .kdlistitemview-member.pending"
    pendingMemberViewTime     = "#{pendingMemberView} time"
    pendingMemberViewSettings = "#{pendingMemberView}.settings-visible .settings"
    actionButton              = "#{pendingMemberViewSettings} .resend-button"

    if revoke
      actionButton = "#{pendingMemberViewSettings} .revoke-button"

    @clickPendingInvitations(browser, no)

    browser
      .waitForElementVisible  pendingMemberViewTime, 20000
      .click                  pendingMemberViewTime
      .waitForElementVisible  actionButton, 20000
      .pause                  3000
      .click                  actionButton
      .pause                  2000

    if revoke
      browser.expect.element(pendingMemberView).text.to.not.contain userEmail
    else
      browser.waitForElementVisible  '.kdnotification', 20000 # Assertion


  searchPendingInvitation: (browser, userEmail) ->

    pendingInvitations  = '.member-related .pending-invitations'
    searchSelector      = "#{pendingInvitations} .search"
    searchInputSelector = "#{searchSelector} input"
    emailList           = "#{pendingInvitations} .listview-wrapper"

    browser
      .waitForElementVisible     searchSelector, 20000
      .waitForElementVisible     searchInputSelector, 20000
      .click                     searchInputSelector
      .setValue                  searchInputSelector, userEmail + browser.Keys.ENTER
      .pause                     5000 # wait for listing
      .waitForElementVisible     emailList, 20000
      .assert.containsText       emailList, userEmail


  likeunlikePost: (browser, likeLikePost = no) ->

    likeContainer       = ".ChatItem .SimpleChatListItem .ChatListItem-itemBodyContainer"
    likeButtonUnpressed = "#{likeContainer} a[class~=ActivityLikeLink]:not(.is-likedByUser)"
    likeButtonPressed   = "#{likeContainer} .ActivityLikeLink.is-likedByUser"
    textSelector        = '.ChatListItem-itemBodyContainer:nth-of-type(1)'

    browser
      .pause                  2000
      .waitForElementVisible  textSelector, 20000
      .moveToElement          textSelector, 10, 10
      .waitForElementVisible  likeButtonUnpressed, 20000
      .click                  likeButtonUnpressed
      .waitForElementVisible  likeButtonPressed, 20000
      .assert.visible         likeButtonPressed

    if likeLikePost
      browser
        .click                    likeButtonPressed
        .waitForElementVisible    likeButtonUnpressed, 20000
        .pause                    3000
        .assert.elementNotPresent likeButtonPressed


  editOrDeletePost: (browser, editPost = no, deletePost = no) ->

    editedmessage       = 'Message after editing'
    textSelector        = '.ChatItem .SimpleChatListItem.ChatItem-contentWrapper .ChatListItem-itemBodyContainer'
    menuButton          = '.SimpleChatListItem.ChatItem-contentWrapper:nth-of-type(1) .ButtonWithMenuWrapper button'
    editButton          = '.ButtonWithMenuItemsList li:nth-child(1)'
    chatInput           = '.editing .ChatItem-updateMessageForm .ChatInputWidget textarea'
    editedText          = '.ChatItem .SimpleChatListItem.edited .ChatListItem-itemBodyContainer .ChatItem-contentBody .MessageBody'
    deleteButton        = '.ButtonWithMenuItemsList li:nth-child(2)'
    confirmDelete       = '.Modal-DeleteItemPrompt .Modal-buttons .Button--danger'
    deletedTextSelector = '.Pane-body .ChatList .ChatItem .SimpleChatListItem .ChatListItem-itemBodyContainer'

    browser
      .waitForElementVisible  textSelector, 20000
      .moveToElement          textSelector, 10, 10
      .waitForElementVisible  menuButton, 20000
      .click                  menuButton

    if editPost
      browser
        .waitForElementVisible  editButton, 20000
        .click                  editButton
        .pause                  3000 # wait for textarea
        .waitForElementVisible  chatInput, 20000
        .clearValue             chatInput
        .setValue               chatInput, editedmessage
        .setValue               chatInput, browser.Keys.ENTER
        .waitForElementVisible  editedText, 20000
        .pause                  2000 # wait for new text
        .assert.containsText    editedText, editedmessage

    if deletePost
      browser
        .waitForElementVisible     deleteButton, 20000
        .click                     deleteButton
        .waitForElementVisible     confirmDelete, 20000
        .click                     confirmDelete
        .pause                     3000 #for the text to be deleted
        .assert.elementNotPresent  deletedTextSelector


  updateChannelPurpose: (browser) ->

    editedPurposeText  = "edited text on the purpose field"
    menuButtonSelector = '.ChannelThreadPane-content .ChannelThreadPane-header .ButtonWithMenuWrapper button'
    editButtonSelector = '.ButtonWithMenuItemsList.ChannelThreadPane-menuItems li:nth-child(3)'
    inputTextSelector  = '.ThreadHeader.ChannelThreadPane-header .ChannelThreadPane-purposeWrapper.editing input'
    editedTextSelector = '.ChannelThreadPane-purposeWrapper .ChannelThreadPane-purpose'

    browser
      .waitForElementVisible  menuButtonSelector, 20000
      .click                  menuButtonSelector
      .waitForElementVisible  editButtonSelector, 20000
      .click                  editButtonSelector
      .waitForElementVisible  inputTextSelector, 20000
      .clearValue             inputTextSelector
      .setValue               inputTextSelector, editedPurposeText + browser.Keys.ENTER
      .pause                  3000 #waiting for the text to change
      .waitForElementVisible  editedTextSelector, 20000
      .assert.containsText    editedTextSelector, editedPurposeText


  createPrivateChat: (browser) ->

    emptyInviteMembersInputText = '.CreateChannel-Modal .CreateChannel-content .channelName input'
    createChatButton            = '.CreateChannel-Modal .Modal-buttons button:first-child'
    markedAsInvalidInputText    = '.CreateChannel-content .channelName.invalid'

    @moveToSidebarHeader(browser, yes)

    browser
      .waitForElementVisible  emptyInviteMembersInputText, 20000
      .waitForElementVisible  createChatButton, 20000
      .click                  createChatButton
      .waitForElementVisible  markedAsInvalidInputText, 20000

