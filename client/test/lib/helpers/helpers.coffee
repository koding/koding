utils    = require '../utils/utils.js'
fail     = require '../utils/fail.js'
register = require '../register/register.js'
faker    = require 'faker'
assert   = require 'assert'
HUBSPOT  = yes


activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =

  beginTest: (browser, user) ->

    url = @getUrl()
    user ?= utils.getUser()

    browser.url url
    browser.maximizeWindow()

    @doLogin browser, user

    browser.execute ->
      window.KD ?= {}
      window.KD.isTesting = yes

    return user


  assertNotLoggedIn: (browser, user) ->

    url = @getUrl()
    browser.url(url)
    browser.maximizeWindow()

    browser.execute ->
      window.KD ?= {}
      window.KD.isTesting = yes

    @attemptLogin(browser, user)

    browser
      .waitForElementVisible   '.flex-wrapper', 20000 # Assertion


  attemptLogin: (browser, user) ->

    if HUBSPOT
      browser
        .waitForElementVisible  '.hero.block .container', 50000
        .click                  '.header__nav .hs-menu-wrapper a[href="/Login"]'
    else
      browser
        .waitForElementVisible  '[testpath=main-header]', 50000
        .click                  'nav:not(.mobile-menu) [testpath=login-link]'

    browser
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
        console.log " ✔ User is not registered yet. Registering... username: #{user.username} and password: #{user.password}"
        @doRegister browser, user


  doLogout: (browser) ->

    browser
      .waitForElementVisible  '[testpath=AvatarAreaIconLink]', 30000
      .click                  '[testpath=AvatarAreaIconLink]'
      .click                  '[testpath=logout-link]'
      .pause                  3000
      if HUBSPOT
        browser.waitForElementVisible  '.hero.block .container', 20000
      else
        browser.waitForElementVisible  '[testpath=main-header]', 30000 # Assertion


  attemptEnterEmailAndPasswordOnRegister: (browser, user) ->

    url = @getUrl()
    browser.url url

    homePageSelector = '.hero.block .container'

    if HUBSPOT
      browser
        .waitForElementVisible  homePageSelector, 20000
        .waitForElementVisible  "#{homePageSelector} a[href='/Register']", 20000
        .click                  "#{homePageSelector} a[href='/Register']"
        .pause 3000
        .waitForElementVisible  '.form-area .main-part', 20000
        .setValue               '.login-form .email input[name=email]', user.email
        .setValue               '.login-form .password input[name=password]', user.password
    else
      browser.setValue  'input[name=password]', user.password

    browser.click       '[testpath=signup-button]'


  attemptEnterUsernameOnRegister: (browser, user) ->

    modalSelector  = '.extra-info.password'
    buttonSelector = "#{modalSelector} button[type=submit]"

    browser.waitForElementVisible modalSelector, 30000

    if user.gravatar
      browser
        .assert.valueContains "#{modalSelector} input[name=username]",  'kodingqa'
        .assert.valueContains "#{modalSelector} input[name=firstName]", 'Koding'
        .assert.valueContains "#{modalSelector} input[name=lastName]",  'Testuser'
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

    unless HUBSPOT
      browser.waitForElementVisible '[testpath=main-header]', 50000 # Assertion
    else
      browser.waitForElementVisible '[testpath=AvatarAreaIconLink]', 50000 # Assertion


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
      .waitForElementVisible    '[testpath="public-feed-link/Activity/Topic/public"]', 20000
      .click                    '[testpath="public-feed-link/Activity/Topic/public"]'
      .pause                    3000 # for page load
      .waitForElementVisible    '[testpath=ActivityInputView]', 30000
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
      .pause                   3000 # wait for
      .setValue                'li.selected .rename-container .hitenterview', folderName + '\n'
      .pause                   3000 # required
      .waitForElementPresent   folderSelector, 50000 # Assertion

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

    @openAvatarAreaModal(browser)

    browser
      .click                   '.avatararea-popup.active .content [testpath=AccountSettingsLink]'
      .waitForElementVisible   '.AppModal--account', 20000


  openAvatarAreaModal: (browser, forTeams) ->

    if forTeams
      browser
        .waitForElementVisible   '.avatar-area .avatarview img', 20000
        .click                   '.avatar-area .avatarview img'
        .waitForElementVisible   '.avatararea-popup.team', 20000
    else
      browser
        .waitForElementVisible   '.avatar-area [testpath=AvatarAreaIconLink]', 20000
        .click                   '.avatar-area [testpath=AvatarAreaIconLink]'
        .waitForElementVisible   '.avatararea-popup.active .content', 20000 # Assertion


  fillPaymentForm: (browser, planType = 'developer', cardDetails = {}) ->

    defaultCard  =
      cardNumber : cardDetails.cardNumber or "4111 1111 1111 1111"
      cvc        : cardDetails.cvc        or 123
      month      : cardDetails.month      or 12
      year       : cardDetails.year       or 2019

    user         = utils.getUser()
    name         = user.username
    paymentModal = '.payment-modal .payment-form-wrapper form.payment-method-entry-form'

    browser
      .waitForElementVisible   '.payment-modal', 20000
      .waitForElementVisible   paymentModal, 20000
      .waitForElementVisible   paymentModal + ' .cardnumber', 20000
      .click                   'input[name=cardNumber]'
      .setValue                'input[name=cardNumber]', defaultCard.cardNumber
      .waitForElementVisible   paymentModal + ' .cardcvc', 20000
      .click                   'input[name=cardCVC]'
      .setValue                'input[name=cardCVC]', defaultCard.cvc
      .waitForElementVisible   paymentModal + ' .cardmonth', 20000
      .click                   'input[name=cardMonth]'
      .setValue                'input[name=cardMonth]', defaultCard.month
      .waitForElementVisible   paymentModal + ' .cardyear', 20000
      .click                   'input[name=cardYear]'
      .setValue                'input[name=cardYear]', defaultCard.year
      .waitForElementVisible   paymentModal + ' .cardname', 20000
      .click                   'input[name=cardName]'
      .clearValue              'input[name=cardName]'
      .setValue                'input[name=cardName]', name

  submitForm: (browser, validCardDetails = yes) ->

    upgradePlanButton = '.kdmodal-inner .green'
    planType          = 'developer'

    if validCardDetails
      browser
        .waitForElementVisible   'button.submit-btn', 20000
        .click                   'button.submit-btn'
        .waitForElementVisible   '.kdmodal-content .success-msg', 20000
        .click                   'button.submit-btn'
        .waitForElementVisible   '[testpath=main-sidebar]', 20000
        .url                     "#{@getUrl()}/Pricing"
        .waitForElementVisible   '.content-page.pricing', 20000
        .waitForElementVisible   '.single-plan.' + planType + '.current', 20000
    else
      browser
        .expect.element(upgradePlanButton).to.not.be.enabled


  selectPlan: (browser, planType = 'developer') ->

    pricingPage = '.content-page.pricing'

    browser
      .waitForElementVisible   pricingPage, 25000
      .waitForElementVisible   pricingPage + ' .plans .' + planType, 25000
      .pause                   5000
      .click                   pricingPage + ' .plans .' + planType + ' .plan-buy-button'
      .pause                   5000


  checkInvalidCardDetails: (browser, cardDetails, submit) ->

    freePlanSelector = '.single-plan.free.current'

    browser
      .url                     "#{@getUrl()}/Pricing"
      .waitForElementVisible   '.content-page.pricing', 20000
      .waitForElementVisible   '.kdtabpaneview .kdview .current', 20000
      .element 'css selector', freePlanSelector, (result) =>
        if result.status is 0
          @selectPlan(browser)
          @fillPaymentForm(browser, 'developer', cardDetails)
          @submitForm(browser, submit)
          browser.end()
        else
          browser.end()

  runCommandOnTerminal: (browser, text) ->

    text or= Date.now()

    browser
      .execute                   "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input('echo #{text}')"
      .execute                   "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"
      .pause                     5000
      .waitForElementVisible     '.panel-1 .panel-1 .kdtabpaneview.terminal.active', 25000
      .assert.containsText       '.panel-1 .panel-1 .kdtabpaneview.terminal.active', text


  setCookie: (browser, name, value) ->

    domain = '.dev.koding.com'

    browser
      .cookie    'POST', { name, value, domain }
      .refresh()


  getUrl: (teamsUrl) ->

    url = 'dev.koding.com:8090'

    if teamsUrl
      user = utils.getUser()
      return "http://#{user.teamSlug}.#{url}"
    else
      return "http://#{url}"
      # return 'http://54.152.13.1:8090'
      # return 'https://koding:1q2w3e4r@sandbox.koding.com/'
