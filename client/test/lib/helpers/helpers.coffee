curl     = require 'curlrequest'
faker    = require 'faker'
utils    = require '../utils/utils.js'
assert   = require 'assert'
HUBSPOT  = no

KONFIG = require 'koding-config-manager'

require '../utils/fail.js' # require fail to wrap NW::fail.


module.exports =

  beginTest: (browser, user, url) ->

    url  or= @getUrl()
    user  ?= utils.getUser()

    browser.url url
    browser.resizeWindow 1440, 900

    @doLogin browser, user

    browser.execute ->
      window.KD ?= {}
      window.KD.isTesting = yes

    return user

  attemptEnterEmailAndPasswordOnRegister: (browser, user) ->

    browser
      .url                    "#{@getUrl()}/RegisterForTests"
      .waitForElementVisible  '.login-screen.register', 30000 # Assertion
      .setValue               'input[testpath=register-form-email]', user.email
      .setValue               'input[testpath=register-password]', user.password
      .click                  '[testpath=signup-button]'


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

    browser.waitForElementVisible '[testpath=AvatarAreaIconLink]', 50000 # Assertion


  getFakeText: ->

    return faker.lorem.paragraph().replace /(?:\r\n|\r|\n)/g, ''


  ###*
  * Switch browser with given current broser and url to check
  * @param browser, {string} url
  * return current browser
  ###
  switchBrowser: (browser, urlToCheck) ->

    browser.window_handles (result) ->
      handle = result.value[1]
      browser
        .switchWindow         handle
        .assert.urlContains   urlToCheck
        .pause                2000
        .closeWindow()
        .switchWindow         result.value[0]


  openFolderContextMenu: (browser, user, folderName) ->

    configPath       = '/home/' + user.username + '/' + folderName
    configSelector   = "span[title='" + configPath + "']"

    @clickVMHeaderButton(browser)

    browser
      .click                   '.context-list-wrapper .refresh'
      .waitForElementVisible   configSelector, 50000
      .click                   configSelector
      .click                   configSelector + ' + .chevron'


  clickVMHeaderButton: (browser) ->

    browser
      .pause                   5000 # wait for filetree load
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header'
      .click                   '.vm-header .chevron'
      .waitForElementPresent   '.context-list-wrapper', 50000


  createFile: ( browser, user, selector, folderName, fileName, callback = -> ) ->

    selector   or= 'li.new-file'
    folderName or= '.config'
    fileName   or= "#{@getFakeText().split(' ')[0]}.txt"
    folderPath = "/home/#{user.username}/#{folderName}"

    @openFolderContextMenu(browser, user, folderName)

    browser
      .waitForElementVisible    selector, 50000
      .click                    selector
      .waitForElementVisible    'li.selected .rename-container .hitenterview', 50000
      .clearValue               'li.selected .rename-container .hitenterview'
      .setValue                 'li.selected .rename-container .hitenterview', fileName + '\n'
      .pause                    3000 # required
      .waitForElementPresent    "span[title='" + folderPath + '/' + fileName + "']", 50000, false, -> callback() # Assertion

    return fileName


  createFileFromMachineHeader: ( browser, user, fileName, shouldAssert = yes, callback = -> ) ->

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
        .waitForElementPresent   fileSelector, 20000, false, -> callback() # Assertion

    return fileName


  createFolder: ( browser, user, callback ) ->

    folderName     = @getFakeText().split(' ')[0]
    folderPath     = '/home/' + user.username + '/' + folderName
    folderSelector = "span[title='" + folderPath + "']"

    browser
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header'
      .click                   '.vm-header .chevron'
      .waitForElementPresent   '.context-list-wrapper', 50000
      .click                   '.context-list-wrapper .refresh'
      .pause                   2000
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header'
      .click                   '.vm-header .chevron'
      .waitForElementVisible   '.context-list-wrapper', 50000
      .click                   '.context-list-wrapper li.new-folder'
      .waitForElementVisible   'li.selected .rename-container .hitenterview', 50000
      .clearValue              'li.selected .rename-container .hitenterview'
      .waitForElementVisible   'li.selected .rename-container .hitenterview', 50000
      .pause                   3000 # wait for
      .setValue                'li.selected .rename-container .hitenterview', folderName + '\n'
      .pause                   3000 # required
      .waitForElementPresent   folderSelector, 50000, false # Assertion

    data = {
      name: folderName
      path: folderPath
      selector: folderSelector
    }

    callback data


  deleteFile: ( browser, fileSelector, callback = -> ) ->

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementVisible     'li.delete', 20000
      .click                     'li.delete'
      .waitForElementVisible     '.delete-container', 20000
      .click                     '.delete-container button.clean-red'
      .waitForElementNotPresent  fileSelector, 2000
      .pause 10, -> callback()


  openChangeTopFolderMenu: (browser) ->

    browser
      .waitForElementVisible   '.vm-header', 50000
      .click                   '.vm-header .buttons'
      .waitForElementVisible   'li.change-top-folder', 50000
      .click                   'li.change-top-folder'


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
      cardNumber : cardDetails.cardNumber or '4111 1111 1111 1111'
      cvc        : cardDetails.cvc        or 123
      month      : cardDetails.month      or 'December'
      year       : cardDetails.year       or 2019

    user               = utils.getUser()
    name               = user.username
    paymentModal       = '.HomeAppView--billing-form'
    cardNumberSelector = '.HomeAppView-input.card-number'
    cvcSelector        = '.HomeAppView-input.cvc'
    monthSelector      = '.HomeAppView-selectBoxWrapper.expiration-month'
    yearSelector       = '.HomeAppView-selectBoxWrapper.expiration-year'
    fullNameSelector   = '.HomeAppView-input.full-name'
    emailSelector      = '.HomeAppView-input.email'

    browser
      .waitForElementVisible   paymentModal, 10000
      .waitForElementVisible   cardNumberSelector, 20000
      .click                   cardNumberSelector
      .setValue                cardNumberSelector, defaultCard.cardNumber

      .waitForElementVisible   cvcSelector, 20000
      .click                   cvcSelector
      .setValue                cvcSelector, defaultCard.cvc

      .waitForElementVisible   monthSelector, 20000
      .click                   monthSelector
      .setValue                monthSelector, defaultCard.month

      .scrollToElement         paymentModal
      .waitForElementVisible   yearSelector, 20000
      .click                   yearSelector
      .setValue                yearSelector, defaultCard.year

      .waitForElementVisible   fullNameSelector, 20000
      .setValue                fullNameSelector, name
      .scrollToElement         paymentModal

      .waitForElementVisible   emailSelector, 20000
      .setValue                emailSelector, user.email
      .pause 5000


  submitForm: (browser, validCardDetails = yes) ->

    upgradePlanButton = '.kdmodal-inner .green:not(.paypal)'
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
        .pause  3000
        .expect.element(upgradePlanButton).to.not.be.enabled


  selectPlan: (browser, planType = 'developer') ->

    pricingPage          = '.content-page.pricing'
    selectButtonSelector = pricingPage + ' .plans .' + planType + ' .plan-buy-button .button-title'

    browser
      .waitForElementVisible   pricingPage, 25000
      .waitForElementVisible   pricingPage + ' .plans .' + planType, 25000
      .pause                   5000
      .click                   selectButtonSelector
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


  runCommandOnTerminal: ( browser, text, callback = -> ) ->

    text or= Date.now()

    browser
      .execute                   "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.server.input('echo #{text}')"
      .execute                   "window._kd.singletons.appManager.frontApp.ideViews.last.tabView.activePane.view.webtermView.terminal.keyDown({type: 'keydown', keyCode: 13, stopPropagation: function() {}, preventDefault: function() {}});"
      .pause                     5000
      .waitForElementVisible     '.panel-1 .panel-1 .kdtabpaneview.terminal.active', 25000
      .assert.containsText       '.panel-1 .panel-1 .kdtabpaneview.terminal.active', text
      .pause 10, -> callback()


  setCookie: (browser, name, value) ->

    domain = ".#{KONFIG.domains.base}"

    browser
      .cookie    'POST', { name, value, domain }
      .refresh()


  notifyTestFailure: (browser, testName) ->

    message = "#{testName} test failed, please check the test..."

    browser.pause(2500).end()


  getUrl: (teamsUrl) ->

    url = "#{KONFIG.domains.base}:#{KONFIG.publicPort}"

    if teamsUrl
      user = utils.getUser()
      return "http://#{user.teamSlug}.#{url}"
    else
      return "http://#{url}"


  changePasswordHelper: (browser, newPassword, confirmPassword, currentPassword, notificationText ) ->
    passwordSelector          = 'input[name=password]'
    confirmPasswordSelector   = 'input[name=confirmPassword]'
    currentPasswordSelector   = 'input[name=currentPassword]'
    saveButtonSelector        = '.my-account .HomeAppView--section.password .button-wrapper button.update-button'

    browser
      .waitForElementVisible   passwordSelector, 20000
      .clearValue              passwordSelector
      .setValue                passwordSelector, newPassword
      .clearValue              confirmPasswordSelector
      .setValue                confirmPasswordSelector, confirmPassword
      .clearValue              currentPasswordSelector
      .setValue                currentPasswordSelector, currentPassword
      .waitForElementVisible   saveButtonSelector, 20000
      .click                   saveButtonSelector
      .waitForElementVisible   '.kdnotification.main', 20000
      .assert.containsText     '.kdnotification.main', notificationText
      .pause  3000
