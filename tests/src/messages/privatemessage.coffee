helpers = require '../helpers/helpers.js'
assert  = require 'assert'
curl    = require 'curlrequest'


module.exports =

  sendPrivateMessage: (browser) ->

    elementSelector = '.activity-sidebar .messages h3.sidebar-title'
    formSelector    = '.new-message-form.with-fields .formline.recipient'
    username        = 'devrim'
    message         = 'Hello'
    messageSelector = '.reply-input-widget.private' + ' [testpath=ActivityInputView]'
    itemSelector    = '.kdlistitemview-dropdown-member span.profile'

    helpers.beginTest(browser)

    browser
      .waitForElementVisible   '[testpath=main-sidebar]', 20000
      .waitForElementVisible   elementSelector, 20000
      .moveToElement           elementSelector + ' a.add-icon', 10, 10
      .click                   elementSelector + ' a.add-icon'
      .waitForElementVisible   '.new-message-form.with-fields' , 20000
      .waitForElementVisible   formSelector, 20000
      .click                   formSelector + ' input[type=text]'
      .setValue                formSelector + ' input[type=text]', username
      .click                   elementSelector + ' a.add-icon'
      .click                   formSelector + ' input[type=text]'
      .waitForElementVisible   itemSelector, 20000
      .click                   itemSelector
      .waitForElementVisible   '.reply-input-widget.private',20000
      .click                   messageSelector
      .setValue                messageSelector, message + '\n'
      .waitForElementVisible   '.message-pane.privatemessage', 20000
      .assert.containsText     '.message-pane.privatemessage', message # Assertion
      .assert.containsText     '.activity-sidebar .messages', 'Devrim Yasar' # Assertion
      .end()
