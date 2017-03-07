utils   = require '../utils/utils.js'
faker   = require 'faker'
testUrl = require('../../../../.config.json').test.url



start = (browser) ->
  browser.url(testUrl)

getText = ->
  return faker.lorem.paragraph().replace(/(?:\r\n|\r|\n)/g, '')

register = (browser) ->
  user = utils.getUser(yes)

  browser
    .waitForElementVisible    '[testpath=main-header]', 10000
    .setValue                 '[testpath=register-form-email]', user.email
    .setValue                 '[testpath=register-form-username]', user.username
    .click                    '[testpath=signup-button]'
    .setValue                 '[testpath=password-input]', user.password
    .setValue                 '[testpath=confirm-password-input]', user.password
    .click                    '[testpath=register-submit-button]'
    .waitForElementVisible    '[testpath=AvatarAreaIconLink]', 10000


login = (browser) ->
  user = utils.getUser()

  browser
    .waitForElementVisible  '[testpath=main-header]', 5000
    .click                  '[testpath=login-link]'
    .waitForElementVisible  '[testpath=login-container]', 5000
    .setValue               '[testpath=login-form-username]', user.username
    .setValue               '[testpath=login-form-password]', user.password
    .click                  '[testpath=login-button]'
    .pause                  5000


postActivity = (browser) ->
  post    = getText()

  browser
    .click                    '[testpath="public-feed-link/Activity/Topic/public"]'
    .waitForElementVisible    '[testpath=ActivityInputView]', 10000
    .click                    '[testpath="ActivityTabHandle-/Activity/Public/Recent"]'
    .click                    '[testpath=ActivityInputView]'
    .setValue                 '[testpath=ActivityInputView]', post
    .click                    '[testpath=post-activity-button]'
    .pause                    6000 # required
    .assert.containsText      '[testpath=ActivityListItemView]:first-child', post # Assertion


postComment = (browser) ->
  comment = getText()

  browser
    .click                    '[testpath="public-feed-link/Activity/Topic/public"]'
    .waitForElementVisible    '[testpath=ActivityInputView]', 10000
    .click                    '[testpath=ActivityListItemView]:first-child [testpath=CommentInputView]'
    .setValue                 '[testpath=ActivityListItemView]:first-child [testpath=CommentInputView]', comment + '\n'
    .pause                    6000 # required
    .assert.containsText      '[testpath=ActivityListItemView]:first-child .comment-body-container', comment # Assertion


likeActivity = (browser) ->
  user             = utils.getUser()
  activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'
  selector         = activitySelector + ' [testpath=activity-like-link]'
  likeElement      = activitySelector + ' .like-summary'

  browser
    .waitForElementVisible    selector, 10000
    .click                    selector
    .waitForElementVisible    likeElement, 10000
    .assert.containsText      likeElement, user.username + ' liked this.'


waitForVMBuilding = (browser) ->
  browser
    .click                    '.vms .machine .vm.koding'
    .waitForElementNotVisible '.env-modal.env-machine-state', 200000
    .pause                    10000


runCommandOnTerminal = (browser) ->
  browser
    .pause 2000, ->
      time = Date.now()
      browser
        .execute              "KD.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input('echo #{time}')"
        .execute              "KD.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"
        .pause                5000
        .assert.containsText  '.terminal-pane .webterm', time


module.exports =

  load: (browser) ->

    start(browser)
    register(browser)
    postActivity(browser)
    postComment(browser)
    likeActivity(browser)
    waitForVMBuilding(browser)

    for [0..5]
      runCommandOnTerminal(browser)
      browser.pause 3000

    browser.end()
