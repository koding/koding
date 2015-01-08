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


  assertNotLoggedIn: (browser, user) ->
    url = @getUrl()
    browser.url(url)
    browser.maximizeWindow()

    browser.execute 'KD.isTesting = true;'

    @attemptLogin(browser, user)

    browser
      .waitForElementVisible   '.flex-wrapper', 20000 # Assertion


  attemptLogin: (browser, user) ->
    browser
      .waitForElementVisible  '[testpath=main-header]', 50000
      .click                  '#main-header [testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 50000
      .setValue               '[testpath=login-form-username]', user.username
      .setValue               '[testpath=login-form-password]', user.password
      .click                  '[testpath=login-button]'
      .pause                  5000

  waitForVMRunning: (browser, machineName) ->
    vmSelector = '.vm.running.koding'

    if machineName
      vmSelector   = '[href="/IDE/'+machineName+'/my-workspace"].running.vm'

    modalSelector  = '.env-modal.env-machine-state'
    loaderSelector = modalSelector + ' .kdloader'
    buildingLabel  = modalSelector + ' .state-label.building'
    turnOnButtonSelector = modalSelector + ' .turn-on.state-button'

    browser.element 'css selector', vmSelector, (result) =>
      if result.status is 0
        console.log 'vm is running'
      else
        console.log 'vm is not running'
        browser
          .waitForElementVisible   modalSelector, 50000
          .element 'css selector', buildingLabel, (result) =>
            if result.status is 0
              console.log 'vm is building, waiting to finish'
              browser
                .waitForElementNotVisible  modalSelector, 300000
                .waitForElementVisible     vmSelector, 30000
            else
              console.log 'turn on button is clicked, waiting for VM turn on'

              browser
                .waitForElementNotVisible  loaderSelector, 50000
                .waitForElementVisible     turnOnButtonSelector, 50000
                .click                     turnOnButtonSelector
                .waitForElementNotVisible  modalSelector, 300000
                .waitForElementVisible     vmSelector, 30000


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


  deleteFile: (browser, fileSelector) ->

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementVisible     'li.delete', 20000
      .click                     'li.delete'
      .waitForElementVisible     '.delete-container', 20000
      .click                     '.delete-container button.clean-red'
      .waitForElementNotPresent  fileSelector, 2000


  attemptEnterEmailAndUsernameOnRegister: (browser, user) ->
    browser
      .url                    @getUrl()
      .waitForElementVisible  '[testpath=main-header]', 10000
      .setValue               '[testpath=register-form-email]', user.email
      .setValue               '[testpath=register-form-username]', user.username
      .click                  '[testpath=signup-button]'

  attemptEnterPasswordOnRegister: (browser, user) ->
    browser
      .waitForElementVisible  '[testpath=password-input]', 10000
      .setValue               '[testpath=password-input]', user.password
      .setValue               '[testpath=confirm-password-input]', user.password
      .click                  '[testpath=register-submit-button]'

  doRegister: (browser, user) ->

    user = utils.getUser(yes) unless user

    @attemptEnterEmailAndUsernameOnRegister(browser, user)

    @attemptEnterPasswordOnRegister(browser, user)

    @doLogout(browser)

    @doLogin(browser, user)


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

    @doPostComment(browser, comment, shouldAssert)

    return comment


  doPostComment: (browser, comment, shouldAssert = yes) ->
    browser
      .click                    activitySelector + ' [testpath=CommentInputView]'
      .setValue                 activitySelector + ' [testpath=CommentInputView]', comment
      .waitForElementVisible    activitySelector + ' .comment-container .comment-input-wrapper', 20000
      .click                    activitySelector + ' .has-markdown' # blur
      .pause                    3000 # content preview
      .click                    activitySelector + ' .comment-container button[testpath=post-activity-button]'

    if shouldAssert
      browser
        .pause               6000 # required
        .assert.containsText '[testpath=ActivityListItemView]:first-child .comment-body-container', comment # Assertion


  doPostActivity: (browser, post, shouldAssert = yes) ->
    browser
      .click                  '[testpath="public-feed-link/Activity/Topic/public"]'
      .waitForElementVisible  '[testpath=ActivityInputView]', 10000
      .click                  '[testpath="ActivityTabHandle-/Activity/Public/Recent"] a'
      .waitForElementVisible  '.most-recent [testpath=activity-list]', 30000
      .click                  '[testpath=ActivityInputView]'
      .setValue               '[testpath=ActivityInputView]', post
      .click                  '.channel-title'
      .click                  '[testpath=post-activity-button]'
      .pause                  6000 # required

    if shouldAssert
      browser.assert.containsText '[testpath=ActivityListItemView]:first-child', post # Assertion


  doFollowTopic: (browser) ->

    hashtag      = @sendHashtagActivity(browser)
    selector     = activitySelector + ' .has-markdown p a:first-child'
    topicLink    = '[testpath=main-sidebar] [testpath="public-feed-link/Activity/Topic/' + hashtag.replace('#', '') + '"]'
    channelTitle = '[testpath=channel-title]'

    browser
      .waitForElementVisible   selector, 25000
      .click                   selector
      .waitForElementVisible   topicLink, 25000
      .waitForElementVisible   channelTitle, 25000
      .assert.containsText     channelTitle, hashtag # Assertion
      .waitForElementVisible   channelTitle + ' .follow', 25000
      .click                   channelTitle + ' .follow'
      .waitForElementVisible   channelTitle + ' .following', 25000 # Assertion

    return hashtag

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
      .waitForElementVisible   webSelector, 50000
      .click                   webSelector
      .click                   webSelector + ' + .chevron'


  createFile: (browser, user, selector) ->

    if not selector
      selector = 'li.new-file'

    @openFolderContextMenu(browser, user, 'Web')

    webPath   = '/home/' + user.username + '/Web'
    paragraph = @getFakeText()
    filename  = paragraph.split(' ')[0] + '.txt'

    browser
      .waitForElementVisible    selector, 50000
      .click                    selector
      .waitForElementVisible    'li.selected .rename-container .hitenterview', 50000
      .clearValue               'li.selected .rename-container .hitenterview'
      .setValue                 'li.selected .rename-container .hitenterview', filename + '\n'
      .pause                    3000 # required
      .waitForElementPresent    "span[title='" + webPath + '/' + filename + "']", 50000 # Assertion

    return filename


  createFolder: (browser, user) ->

    folderName     = @getFakeText().split(' ')[0]
    folderPath     = '/home/' + user.username + '/' + folderName
    folderSelector = "span[title='" + folderPath + "']"

    browser
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header .buttons'
      .waitForElementPresent   '.context-list-wrapper', 50000
      .click                   '.context-list-wrapper .refresh'
      .pause                   2000
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header .buttons'
      .waitForElementVisible   '.context-list-wrapper',50000
      .click                   '.context-list-wrapper li.new-folder'
      .waitForElementVisible   'li.selected .rename-container .hitenterview', 50000
      .clearValue              'li.selected .rename-container .hitenterview'
      .waitForElementVisible   'li.selected .rename-container .hitenterview', 50000
      .setValue                'li.selected .rename-container .hitenterview', folderName + '\n'
      .pause                    3000 # required
      .waitForElementPresent    folderSelector, 50000 # Assertion

    data = {
      name: folderName
      path: folderPath
      selector: folderSelector
    }

    return data


  openChangeTopFolderMenu: (browser) ->

    browser
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header .buttons'
      .waitForElementVisible   'li.change-top-folder', 50000
      .click                   'li.change-top-folder'


  createWorkspace: (browser) ->

    paragraph     = @getFakeText()
    workspaceName = paragraph.split(' ')[0]

    browser
      .waitForElementVisible   '.kdscrollview li a.more-link', 20000
      .click                   '.kdscrollview li a.more-link'
      .waitForElementVisible   '.kdmodal-inner', 20000
      .click                   '.kdmodal-inner button'
      .pause                   3000 # required
      .waitForElementVisible   '.add-workspace-view', 20000
      .setValue                '.add-workspace-view input.kdinput.text', workspaceName + '\n'
      .waitForElementVisible   '.vm-info', 20000
      .url (data) =>
        url    = data.value
        vmName = url.split('/IDE/')[1].split('/')[0]

        browser
          .waitForElementPresent   'a[href="/IDE/' + vmName + '/' + workspaceName + '"]', 40000 # Assertion
          .pause                   10000
          .assert.urlContains      workspaceName # Assertion
          .waitForElementVisible   '.vm-info', 20000
          .assert.containsText     '.vm-info', '~/Workspaces/' + workspaceName # Assertion

    return workspaceName


  deleteWorkspace: (browser, workspaceName) ->

    browser.url (data) =>
      url               = data.value
      vmName            = url.split('/IDE/')[1].split('/')[0]
      workspaceSelector = 'a[href="/IDE/' + vmName + '/' + workspaceName + '"]'
      modalSelector     = '.activity-modal.ws-settings'

      browser
        .waitForElementVisible     workspaceSelector, 20000
        .click                     workspaceSelector
        .click                     workspaceSelector + ' .ws-settings-icon'
        .waitForElementVisible     modalSelector, 20000
        .click                     modalSelector + ' button.red'
        .waitForElementNotVisible  workspaceSelector, 20000


  splitPanesUndo: (browser) ->

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


  assertMainHeader: (browser, assertLoginLink = yes) ->

    logoSelector = '[testpath=main-header] a#koding-logo'
    loginLinkSelector = '[testpath=main-header] [testpath=login-link]'

    browser.waitForElementVisible logoSelector, 25000

    if assertLoginLink
      browser.waitForElementVisible loginLinkSelector, 25000


  changeName: (browser, inputSelector, shouldAssertSidebar) ->

    paragraph           = @getFakeText()
    newName             = paragraph.split(' ')[0]
    avatarSelector      = '.avatar-area a.profile'
    accountPageSelector = '#main-panel-wrapper .user-profile'
    saveButtonSelector  = accountPageSelector + ' .button-field .profile-save-changes'

    browser
      .waitForElementVisible   '.avatar-area [testpath=AvatarAreaIconLink]', 20000
      .click                   '.avatar-area [testpath=AvatarAreaIconLink]'
      .waitForElementVisible   '.avatararea-popup .content', 20000
      .click                   '.avatararea-popup .content [testpath=AccountSettingsLink]'
      .waitForElementVisible   accountPageSelector, 20000
      .waitForElementVisible   inputSelector, 20000
      .clearValue              inputSelector
      .setValue                inputSelector, newName + '\n'
      .waitForElementVisible   saveButtonSelector, 20000
      .click                   saveButtonSelector
      .refresh()
      .waitForElementVisible   inputSelector, 20000
      .getValue                inputSelector, (result) ->
        assert.equal           result.value, newName

        if shouldAssertSidebar
          browser
            .waitForElementVisible   avatarSelector, 20000
            .assert.containsText     avatarSelector, newName


  getUrl: ->
    return 'http://lvh.me:8090'
    # return 'https://koding:1q2w3e4r@sandbox.koding.com/'
