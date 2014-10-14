utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'


module.exports =


  postActivity: (browser) ->

    helpers.postActivity(browser)

    browser.end()


  postComment: (browser) ->

    helpers.postComment(browser)

    browser.end()


  likeActivity: (browser) ->

    helpers.postActivity(browser)
    selector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child [testpath=activity-like-link]'

    browser
      .waitForElementVisible selector, 10000
      .click                 selector

    browser.waitForElementVisible selector + '.liked:not(.count)', 10000 # Assertion

    browser.end()


  editPost: (browser) ->

    helpers.postActivity(browser)

    post        =  faker.Lorem.paragraph().replace(/(?:\r\n|\r|\n)/g, '')
    selector    = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

    browser
      .waitForElementVisible      selector + ' .settings-menu-wrapper', 10000
      .click                      selector + ' .settings-menu-wrapper'
      .click                      '.kdcontextmenu .edit-post'
      .clearValue                 selector + ' .edit-widget [testpath=ActivityInputView]'
      .setValue                   selector + ' .edit-widget [testpath=ActivityInputView]', post + '\n'
      .pause                      3000

    browser
      .assert.containsText selector, post # Assertion
      .end()


  deletePost: (browser) ->

    helpers.postActivity(browser)
    helpers.postActivity(browser, no)

    post        =  faker.Lorem.paragraph().replace(/(?:\r\n|\r|\n)/g, '')
    selector    = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

    browser
      .waitForElementVisible        selector + ' .settings-menu-wrapper', 10000
      .click                        selector + ' .settings-menu-wrapper'
      .click                        '.kdcontextmenu .delete-post'
      .click                        '.kdmodal-inner .modal-clean-red'
      .pause                        3000, ->
        text = browser.getText selector
        assert.notEqual text, post # Assertion
      .end()


  likeComment: (browser) ->

    helpers.postComment(browser)

    comment         =  faker.Lorem.paragraph().replace(/(?:\r\n|\r|\n)/g, '')
    selector        = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'
    commentSelector = selector + ' .comment-container .kdlistitemview-comment:first-child'

    browser
      .waitForElementVisible    commentSelector, 3000
      .click                    commentSelector + ' [testpath=activity-like-link]'
      .waitForElementVisible    commentSelector + ' .liked:not(.count)', 10000 # Assertion
      .end()
