utils    = require '../utils/utils.js'
register = require '../register/register.js'
faker    = require 'faker'
assert   = require 'assert'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =

  beginTest: (browser, user) ->
    url  = @getUrl()

    if not user
      user = utils.getUser()

    browser.url(url)
    browser.maximizeWindow()

    @doLogin(browser, user)

    browser.execute 'KD.isTesting = true;'

    return user



  attemptLogin: (browser, user) ->
    browser
      .waitForElementVisible  '[testpath=main-header]', 50000
      .click                  '#main-header [testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 50000
      .setValue               '[testpath=login-form-username]', user.username
      .setValue               '[testpath=login-form-password]', user.password
      .click                  '[testpath=login-button]'
      .pause                  5000


  doLogin: (browser, user) ->
    @attemptLogin(browser, user)

    browser
      .element                'css selector', '[testpath=main-sidebar]', (result) =>
        if result.status is 0
          console.log 'log in success'

          browser.waitForElementVisible '[testpath=main-sidebar]', 10000 # Assertion
        else
          console.log 'user is not registered yet. registering the user.'

          @doRegister browser, user


  doLogout: (browser) ->

    browser
      .waitForElementVisible  '[testpath=AvatarAreaIconLink]', 10000
      .click                  '[testpath=AvatarAreaIconLink]'
      .click                  '[testpath=logout-link]'
      .pause                  3000
      .waitForElementVisible  '[testpath=main-header]', 10000 # Assertion


  doRegister: (browser, user) ->

    user    = utils.getUser(yes) unless user
    url     = @getUrl()

    browser
      .url                    @getUrl()
      .waitForElementVisible  '[testpath=main-header]', 10000
      .setValue               '[testpath=register-form-email]', user.email
      .setValue               '[testpath=register-form-username]', user.username
      .click                  '[testpath=signup-button]'
      .setValue               '[testpath=password-input]', user.password
      .setValue               '[testpath=confirm-password-input]', user.password
      .click                  '[testpath=register-submit-button]'

    @doLogout browser

    @doLogin browser, user


  postActivity: (browser, shouldBeginTest = yes) ->

    if shouldBeginTest
      @beginTest(browser)

    post = @getFakeText()

    @doPostActivity(browser, post)

    return post


  postComment: (browser, shouldPostActivity = yes, shouldAssert = yes) ->

    if shouldPostActivity
      @postActivity(browser)

    comment = @getFakeText()

    browser
      .click        '[testpath=ActivityListItemView]:first-child [testpath=CommentInputView]'
      .setValue     '[testpath=ActivityListItemView]:first-child [testpath=CommentInputView]', comment + '\n'

    if shouldAssert
      browser
        .pause               6000 # required
        .assert.containsText '[testpath=ActivityListItemView]:first-child .comment-body-container', comment # Assertion

    return comment


  doPostActivity: (browser, post) ->

    browser
      .click                  '[testpath="public-feed-link/Activity/Topic/public"]'
      .waitForElementVisible  '[testpath=ActivityInputView]', 10000
      .click                  '[testpath="ActivityTabHandle-/Activity/Public/Recent"]'
      .click                  '[testpath=ActivityInputView]'
      .setValue               '[testpath=ActivityInputView]', post
      .click                  '[testpath=post-activity-button]'
      .pause                  6000 # required

    browser.assert.containsText '[testpath=ActivityListItemView]:first-child', post # Assertion


  sendHashtagActivity: (browser) ->

    @beginTest(browser)

    paragraph = @getFakeText()
    hashtag   = '#' + paragraph.split(' ')[0]
    post      = paragraph + ' ' + hashtag

    @doPostActivity(browser, post)

    browser.assert.containsText activitySelector + ' .has-markdown p a:first-child', hashtag # Assertion

    return hashtag


  getFakeText: ->
    return faker.Lorem.paragraph().replace /(?:\r\n|\r|\n)/g, ''


  openFolderContextMenu: (browser, user, folderName) ->

    webPath       = '/home/' + user.username + '/' + folderName
    webSelector   = "span[title='" + webPath + "']"

    browser
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header .buttons'
      .waitForElementPresent   '.context-list-wrapper', 50000
      .click                   '.context-list-wrapper .refresh'
      .waitForElementVisible   webSelector, 10000
      .click                   webSelector
      .click                   webSelector + ' + .chevron'


  createFile: (browser, user) ->

    @openFolderContextMenu(browser, user, 'Web')

    webPath   = '/home/' + user.username + '/Web'
    paragraph = @getFakeText()
    filename  = paragraph.split(' ')[0] + '.txt'

    browser
      .waitForElementVisible    'li.new-file', 50000
      .click                    'li.new-file'
      .waitForElementVisible    'li.selected .rename-container .hitenterview', 5000
      .clearValue               'li.selected .rename-container .hitenterview'
      .setValue                 'li.selected .rename-container .hitenterview', filename + '\n'
      .pause                    2000 # required
      .waitForElementPresent    "span[title='" + webPath + '/' + filename + "']", 5000 # Assertion

    return filename


  openChangeTopFolderMenu: (browser) ->

    browser
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header .buttons'
      .waitForElementVisible   'li.change-top-folder', 50000
      .click                   'li.change-top-folder'


  createWorkspace: (browser) ->

    @beginTest(browser)

    paragraph     = @getFakeText()
    workspaceName = paragraph.split(' ')[0]

    browser
      .waitForElementVisible   '.kdscrollview li a.more-link', 20000
      .pause                   1000
      .click                   '.kdscrollview li a.more-link'
      .waitForElementVisible   '.kdmodal-inner', 20000
      .click                   '.kdmodal-inner button'
      .pause                   2000 # required
      .waitForElementVisible   '.add-workspace-view', 20000
      .setValue                '.add-workspace-view input.kdinput.text', workspaceName + '\n'
      .waitForElementVisible   '.vm-info', 20000
      .pause                   2000, =>

        browser.url (data) =>
          url    = data.value
          vmName = url.split('/IDE/')[1].split('/')[0]

          browser
            .assert.urlContains      workspaceName # Assertion
            .assert.containsText     '.vm-info', '~/Workspaces/' + workspaceName # Assertion
            .waitForElementPresent   'a[href="/IDE/' + vmName + '/' + workspaceName + '"]', 20000 # Assertion

    return workspaceName


  splitPanesUndo: (browser) ->

    @beginTest(browser)

    browser
      .waitForElementVisible '.panel-1', 20000
      .elements 'css selector', '.panel-1', (result) =>
        assert.equal result.value.length, 2

        browser
          .waitForElementVisible   '.application-tab-handle-holder', 20000
          .click                   '.application-tab-handle-holder .plus'
          .waitForElementVisible   '.context-list-wrapper', 20000
          .click                   '.context-list-wrapper li.undo-split'
          .pause                   2000

        .elements 'css selector', '.panel-1', (result) =>
          assert.equal result.value.length, 1



  getUrl: ->
    return 'http://lvh.me:8090'
    # return 'https://koding:1q2w3e4r@sandbox.koding.com/'
