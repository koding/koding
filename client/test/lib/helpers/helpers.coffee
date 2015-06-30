utils    = require '../utils/utils.js'
register = require '../register/register.js'
faker    = require 'faker'
assert   = require 'assert'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =

  beginTest: (browser, user) ->

    url   = @getUrl()
    user ?= utils.getUser()

    browser.url url
    browser.maximizeWindow()

    @doLogin browser, user

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
      .click                  'nav:not(.mobile-menu) [testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 50000
      .setValue               '[testpath=login-form-username]', user.username
      .setValue               '[testpath=login-form-password]', user.password
      .click                  '[testpath=login-button]'
      .pause                  2500 # required, wait for login complete


  doLogin: (browser, user) ->

    @attemptLogin(browser, user)

    browser.element 'css selector', '[testpath=main-sidebar]', (result) =>
      if result.status is 0
        console.log " ✔ Successfully logged in with username: #{user.username} and password: #{user.password}"
      else
        console.log ' ✔ User is not registered yet. Registering...'
        @doRegister browser, user


  doLogout: (browser) ->

    browser
      .waitForElementVisible  '[testpath=AvatarAreaIconLink]', 10000
      .click                  '[testpath=AvatarAreaIconLink]'
      .click                  '[testpath=logout-link]'
      .pause                  3000
      .waitForElementVisible  '[testpath=main-header]', 10000 # Assertion


  attemptEnterEmailAndPasswordOnRegister: (browser, user) ->

    browser
      .url                    @getUrl()
      .waitForElementVisible  '[testpath=main-header]', 10000
      .setValue               '[testpath=register-form-email]', user.email
      .setValue               'input[name=password]', user.password
      .click                  '[testpath=signup-button]'


  attemptEnterUsernameOnRegister: (browser, user) ->

    modalSelector  = '.extra-info.password'
    buttonSelector = 'button[type=submit]'

    browser.waitForElementVisible modalSelector, 10000

    if user.gravatar
      browser
        .assert.valueContains 'input[name=username]',  'kodingtestuser'
        .assert.valueContains 'input[name=firstName]', 'Koding'
        .assert.valueContains 'input[name=lastName]',  'Testuser'
    else
      browser
        .setValue '[testpath=register-form-username]', user.username

    browser
      .pause    2000
      .click    modalSelector
      .click    buttonSelector


  doRegister: (browser, user) ->

    user = utils.getUser(yes) unless user

    @attemptEnterEmailAndPasswordOnRegister(browser, user)
    @attemptEnterUsernameOnRegister(browser, user)
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


  doPostComment: (browser, comment, shouldAssert = yes, hasEmbeddable = no) ->

    browser
      .click                    activitySelector + ' [testpath=CommentInputView]'
      .setValue                 activitySelector + ' [testpath=CommentInputView]', comment
      .waitForElementVisible    activitySelector + ' .comment-container .comment-input-wrapper', 20000
      .click                    activitySelector + ' .has-markdown' # blur
      .pause                    3000 # content preview

    if hasEmbeddable
      browser
        .waitForElementVisible  '.comment-input-widget .link-embed-box', 20000

    browser
      .click                    activitySelector + ' .comment-container button[testpath=post-activity-button]'


    if shouldAssert
      browser
        .pause               6000 # required
        .assert.containsText '[testpath=ActivityListItemView]:first-child .comment-body-container', comment # Assertion


  doPostActivity: (browser, post, shouldAssert = yes, hasEmbeddable = no) ->

    browser
      .pause                    2500 # while typing something steals activity input focus
      .click                    '[testpath="public-feed-link/Activity/Topic/public"]'
      .waitForElementVisible    '[testpath=ActivityInputView]', 10000
      .click                    '[testpath="ActivityTabHandle-/Activity/Public/Recent"] a'
      .waitForElementVisible    '.most-recent [testpath=activity-list]', 30000
      .click                    '[testpath=ActivityInputView]'
      .setValue                 '[testpath=ActivityInputView]', post
      .click                    '.channel-title'

    if hasEmbeddable
      browser
        .waitForElementVisible  '[testpath=ActivityInputWidget] .link-embed-box', 20000

    browser
      .click                    '[testpath=post-activity-button]'
      .pause                    6000 # required

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


  likePost: (browser, user) ->

    post = @postActivity(browser, no)
    selector    = activitySelector + ' [testpath=activity-like-link]'
    likeElement = activitySelector + ' .like-summary'

    browser
      .waitForElementVisible selector, 25000
      .click                 selector
      .waitForElementVisible likeElement, 25000
      .assert.containsText   likeElement, user.username + ' liked this.'

    return post


  sendHashtagActivity: (browser) ->

    paragraph = @getFakeText()
    hashtag   = '#' + paragraph.split(' ')[0] + Date.now()
    post      = paragraph + ' ' + hashtag

    @doPostActivity(browser, post)

    browser.assert.containsText activitySelector + ' .has-markdown p a:first-child', hashtag # Assertion

    return hashtag


  getFakeText: ->

    return faker.Lorem.paragraph().replace /(?:\r\n|\r|\n)/g, ''


  openFolderContextMenu: (browser, user, folderName) ->

    webPath       = '/home/' + user.username + '/' + folderName
    webSelector   = "span[title='" + webPath + "']"

    @clickVMHeaderButton(browser)

    browser
      .click                   '.context-list-wrapper .refresh'
      .waitForElementVisible   webSelector, 50000
      .click                   webSelector
      .click                   webSelector + ' + .chevron'


  clickVMHeaderButton: (browser) ->

    browser
      .pause                   5000 # wait for filetree load
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header .buttons'
      .waitForElementPresent   '.context-list-wrapper', 50000


  createFile: (browser, user, selector, folderName) ->

    if not selector
      selector = 'li.new-file'

    if not folderName
      folderName = 'Web'

    @openFolderContextMenu(browser, user, folderName)

    folderPath = "/home/#{user.username}/#{folderName}"
    paragraph  = @getFakeText()
    filename   = paragraph.split(' ')[0] + '.txt'

    browser
      .waitForElementVisible    selector, 50000
      .click                    selector
      .waitForElementVisible    'li.selected .rename-container .hitenterview', 50000
      .clearValue               'li.selected .rename-container .hitenterview'
      .setValue                 'li.selected .rename-container .hitenterview', filename + '\n'
      .pause                    3000 # required
      .waitForElementPresent    "span[title='" + folderPath + '/' + filename + "']", 50000 # Assertion

    return filename


  createFileFromMachineHeader: (browser, user, fileName, shouldAssert = yes) ->

    unless fileName
      fileName    = @getFakeText().split(' ')[0] + '.txt'

    filePath      = '/home/' + user.username
    fileSelector  = "span[title='" + filePath + '/' + fileName + "']"
    inputSelector = '.rename-container input.hitenterview'

    browser
      .waitForElementVisible     '.vm-header', 20000
      .click                     '.vm-header span.chevron'
      .waitForElementVisible     '.context-list-wrapper', 20000
      .click                     '.context-list-wrapper li.new-file'
      .waitForElementVisible     inputSelector, 20000
      .click                     inputSelector
      .clearValue                inputSelector
      .pause  2000
      .setValue                  inputSelector, fileName + '\n'

    if shouldAssert
      browser
        .waitForElementPresent   fileSelector, 20000 # Assertion

    return fileName


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


  openChangeTopFolderMenu: (browser) ->

    browser
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header .buttons'
      .waitForElementVisible   'li.change-top-folder', 50000
      .click                   'li.change-top-folder'


  createWorkspace: require './createworkspace'


  deleteWorkspace: (browser, workspaceName) ->

    browser.url (data) =>
      url               = data.value
      vmName            = url.split('/IDE/')[1].split('/')[0]
      workspaceSelector = 'a[href="/IDE/' + vmName + '/' + workspaceName + '"]'
      modalSelector     = '.activity-modal.ws-settings'

      browser
        .waitForElementVisible     workspaceSelector, 20000
        .click                     workspaceSelector
        .click                     workspaceSelector + ' + .ws-settings-icon'
        .waitForElementVisible     modalSelector, 20000
        .click                     modalSelector + ' button.red'
        .waitForElementNotVisible  workspaceSelector, 20000


  waitForVMRunning: require './waitforvmrunning'


  changeName: (browser, inputSelector, shouldAssertSidebar) ->

    paragraph          = @getFakeText()
    newName            = paragraph.split(' ')[0]
    avatarSelector     = '.avatar-area a.profile'
    saveButtonSelector = '.AppModal--account .button-field'

    @openAccountPage(browser)

    browser
      .waitForElementVisible   inputSelector, 20000
      .clearValue              inputSelector
      .setValue                inputSelector, newName + '\n'
      .waitForElementVisible   saveButtonSelector, 20000
      .click                   saveButtonSelector
      .waitForElementVisible   '.kdnotification.main', 20000
      .refresh()
      .waitForElementVisible   inputSelector, 20000
      .getValue                inputSelector, (result) ->
        assert.equal           result.value, newName

        if shouldAssertSidebar
          browser
            .waitForElementVisible   avatarSelector, 20000
            .assert.containsText     avatarSelector, newName


  openAccountPage: (browser) ->

    browser
      .waitForElementVisible   '.avatar-area [testpath=AvatarAreaIconLink]', 20000
      .click                   '.avatar-area [testpath=AvatarAreaIconLink]'
      .waitForElementVisible   '.avatararea-popup .content', 20000
      .click                   '.avatararea-popup .content [testpath=AccountSettingsLink]'
      .waitForElementVisible   '.AppModal--account', 20000


  fillPaymentForm: (browser, planType = 'developer') ->

    user          = utils.getUser()
    name          = user.username
    paymentModal  = '.payment-modal .payment-form-wrapper form.payment-method-entry-form'
    cardNumber    = '4111 1111 1111 1111'
    cvc           = '123'
    month         = '12'
    year          = '2017'

    browser
      .waitForElementVisible   '.payment-modal', 20000
      .waitForElementVisible   paymentModal, 20000
      .waitForElementVisible   paymentModal + ' .cardnumber', 20000
      .click                   'input[name=cardNumber]'
      .setValue                'input[name=cardNumber]', cardNumber
      .waitForElementVisible   paymentModal + ' .cardcvc', 20000
      .click                   'input[name=cardCVC]'
      .setValue                'input[name=cardCVC]', cvc
      .waitForElementVisible   paymentModal + ' .cardmonth', 20000
      .click                   'input[name=cardMonth]'
      .setValue                'input[name=cardMonth]', month
      .waitForElementVisible   paymentModal + ' .cardyear', 20000
      .click                   'input[name=cardYear]'
      .setValue                'input[name=cardYear]', year
      .waitForElementVisible   paymentModal + ' .cardname', 20000
      .click                   'input[name=cardName]'
      .setValue                'input[name=cardName]', name
      .click                   '.year-price-msg'
      .waitForElementVisible   'button.submit-btn', 20000
      .click                   'button.submit-btn'
      .waitForElementVisible   '.kdmodal-content .success-msg', 20000
      .click                   'button.submit-btn'
      .waitForElementVisible   '[testpath=main-sidebar]', 20000
      .url                     @getUrl() + '/Pricing'
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.single-plan.' + planType + '.current', 20000


  selectPlan: (browser, planType = 'developer') ->

    pricingPage = '.content-page.pricing'

    browser
      .waitForElementVisible   pricingPage, 25000
      .waitForElementVisible   pricingPage + ' .plans .' + planType, 25000
      .pause                   5000
      .click                   pricingPage + ' .plans .' + planType + ' .plan-buy-button'
      .pause                   5000


  getUrl: ->

    return 'http://dev.koding.com:8090'
    # return 'http://54.165.211.40:8090'
    # return 'https://koding:1q2w3e4r@sandbox.koding.com/'
