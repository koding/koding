helpers = require './helpers.js'
assert  = require 'assert'


module.exports =

  startConversation: (browser, user, message) ->

    elementSelector    = '.activity-sidebar .messages h3.sidebar-title'
    formSelector       = '.new-message-form.with-fields .formline.recipient'
    textareaSelector   = '.reply-input-widget.private [testpath=ActivityInputView]'
    itemSelector       = '.kdlistitemview-dropdown-member span.profile'
    messageSelector    = "[testpath=main-sidebar] .profile[href='/#{user.userName}']"
    message          or= 'Hello World!'

    browser.element 'css selector', messageSelector, (result) =>
      if result.status is 0
        console.log "✔  A message thread with the same user is already exists. Ending test."
        return yes
      else
        console.log "✔  Creating a new message with user #{user.userName}..."
        browser
          .waitForElementVisible   '[testpath=main-sidebar]', 20000
          .waitForElementVisible   elementSelector, 20000
          .moveToElement           elementSelector + ' a.add-icon', 10, 10
          .click                   elementSelector + ' a.add-icon'
          .waitForElementVisible   '.new-message-form.with-fields' , 20000
          .waitForElementVisible   formSelector, 20000
          .click                   formSelector + ' input[type=text]'
          .setValue                formSelector + ' input[type=text]', user.userName
          .click                   elementSelector + ' a.add-icon'
          .click                   formSelector + ' input[type=text]'
          .waitForElementVisible   itemSelector, 20000
          .click                   itemSelector
          .waitForElementVisible   '.reply-input-widget.private',20000
          .click                   textareaSelector
          .setValue                textareaSelector, message + '\n'
          .waitForElementVisible   '.message-pane.privatemessage', 20000
          .assert.containsText     '.message-pane.privatemessage', message # Assertion
          .waitForElementVisible   '.message-pane.privatemessage .with-parent', 20000
          .assert.containsText     '.activity-sidebar .messages', user.fullName # Assertion
