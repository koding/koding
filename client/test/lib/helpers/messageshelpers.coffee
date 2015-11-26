helpers = require './helpers.js'
assert  = require 'assert'


module.exports =

  startConversation: (browser, users, message, purpose) ->

    elementSelector     = '.activity-sidebar .messages h3.sidebar-title'
    purposeSelector     = '.sidebar-message-text .purpose'
    formSelector        = '.new-message-form.with-fields .formline.recipient'
    textareaSelector    = '.reply-input-widget.private [testpath=ActivityInputView]'
    itemSelector        = '.private-message:not(.hidden) span.profile'
    sidebarTextSelector = '.activity-sidebar .messages .sidebar-message-text'
    messageSelector     = "#{sidebarTextSelector} [href='/#{users[0].username}']"
    message           or= 'Hello World!'
    messageWithCode     = "console.log('123456789')"
    messageWithFullCode = "```console.log('123456789')```"
    textSelector        = '.message-pane.privatemessage .message-pane-scroller .kdscrollview .kdlistview-privatemessage .consequent'
    imageSelector       = "#{textSelector} .link-embed-box .embed-image-view img"
    linkSelector        = "[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView] .link-embed-box .with-image .preview-text a:nth-of-type(2)"
    messageWithImage    = "https://koding-cdn.s3.amazonaws.com/images/default.avatar.333.png"
    messageWithLink     = "http://wikipedia.org/"
    sendMessage         = (browser, users, message, purpose) ->
      console.log " ✔ Creating a new message with user #{users[0].username}..."
      browser
        .waitForElementVisible   '[testpath=main-sidebar]', 20000
        .waitForElementVisible   elementSelector, 20000
        .moveToElement           elementSelector + ' a.add-icon', 10, 10
        .click                   elementSelector + ' a.add-icon'
        .waitForElementVisible   '.new-message-form.with-fields' , 20000
        .waitForElementVisible   formSelector, 20000

        for user in users
          browser
            .click                   formSelector + ' input[type=text]'
            .setValue                formSelector + ' input[type=text]', user.username
            .click                   elementSelector + ' a.add-icon'
            .click                   formSelector + ' input[type=text]'
            .waitForElementVisible   itemSelector, 20000
            .click                   itemSelector

        if purpose
          browser
            .waitForElementVisible  '.purpose input[name=purpose]', 20000
            .setValue               '.purpose input[name=purpose]', purpose

        browser
          .waitForElementVisible   '.reply-input-widget.private',20000
          .click                   textareaSelector
          .setValue                textareaSelector, message
          .pause                   2000 #in order for the previews to load
          .setValue                textareaSelector, browser.Keys.ENTER
          .waitForElementVisible   '.message-pane.privatemessage', 20000
          .waitForElementVisible   '[testpath=activity-list]', 20000
          switch message
            when messageWithFullCode
              browser
                .assert.containsText     textSelector, messageWithCode
            when messageWithImage
              browser
                .waitForElementVisible   imageSelector, 20000

              browser.getAttribute imageSelector, 'height', (result) ->
                height = result.value
                assert.equal('333', height)
            when messageWithLink
              browser
                .waitForElementVisible    linkSelector, 20000
                .assert.containsText      linkSelector, 'The Free Encyclopedia' 
            else
              browser
                .assert.containsText     '.message-pane.privatemessage', message # Assertion
                .waitForElementVisible   '.message-pane.privatemessage .with-parent', 20000
                if purpose
                  browser.assert.containsText '.activity-sidebar .messages', purpose # Assertion
                else
                  browser.assert.containsText '.activity-sidebar .messages', users[0].username # Assertion

                  for user in users
                    browser.waitForElementPresent "#{sidebarTextSelector} [href='/#{user.username}']", 20000

    if purpose
      browser.element 'css selector', purposeSelector, (result) =>
        if result.status is 0
          console.log " ✔ A message thread with the same purpose is already exists. Ending test."
          return yes
        else
          sendMessage browser, users, message, purpose
    else
      browser.element 'css selector', messageSelector, (result) =>
        if result.status is 0
          console.log " ✔ A message thread with the same user is already exists. Ending test."
          return yes
        else
          sendMessage browser, users, message


  leaveConversation: (browser, user, message) ->

    buttonSelector          = '.privatemessage .chat-heads span.chevron'
    listWrapperSelector     = '.context-list-wrapper li.leave-conversation'
    sidebarMessageSelector  = '.activity-sidebar .messages'

    browser
      .waitForElementVisible  '.privatemessage .chat-heads', 20000
      .waitForElementVisible  buttonSelector, 20000
      .click                  buttonSelector
      .waitForElementVisible  listWrapperSelector, 20000
      .click                  listWrapperSelector
      .waitForElementVisible  '.kdmodal-inner', 20000
      .click                  '.kdmodal-inner .kdmodal-buttons button.red'
      .waitForElementVisible  sidebarMessageSelector, 20000, ->
        text = browser.getText sidebarMessageSelector
        assert.notEqual text, user.username # Assertion
