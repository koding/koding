utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'


module.exports =


  openFile: (browser) ->

    user = helpers.beginTest(browser)

    helpers.openFolderContextMenu(browser, user, 'Web')

    webPath       = '/home/' + user.username + '/Web'
    indexSelector = "span[title='" + webPath + '/index.html' + "']"

    browser
      .waitForElementVisible   'li.expand', 15000
      .click                   'li.expand'
      .waitForElementVisible   indexSelector, 15000
      .click                   indexSelector
      .click                   indexSelector + ' + .chevron'
      .waitForElementVisible   'li.open-file', 20000
      .click                   'li.open-file'
      .waitForElementVisible   '.indexhtml',   20000 # Assertion
      .waitForElementVisible   '.ace_content', 20000# Assertion
      .assert.containsText     '.ace_content', 'Hello World from HTML by Koding' # Assertion
      .end()


  createNewFile: (browser) ->

    user = helpers.beginTest(browser)
    helpers.createFile(browser, user)
    browser.end()


  deleteFile: (browser) ->

    user         = helpers.beginTest(browser)
    filename     = helpers.createFile(browser, user)
    webPath      = '/home/' + user.username + '/Web'
    fileSelector = "span[title='" + webPath + '/' + filename + "']"

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementVisible     'li.delete', 20000
      .click                     'li.delete'
      .waitForElementVisible     '.delete-container', 20000
      .click                     '.delete-container button.clean-red'
      .waitForElementNotPresent  fileSelector, 20000
      .end()


  rename: (browser) ->

    user         = helpers.beginTest(browser)
    filename     = helpers.createFile(browser, user)
    webPath      = '/home/' + user.username + '/Web'
    fileSelector = "span[title='" + webPath + '/' + filename + "']"

    paragraph        = helpers.getFakeText()
    newFileName      = paragraph.split(' ')[0] + '.txt'
    newFileSelector  = "span[title='" + webPath + '/' + newFileName + "']"

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementVisible     'li.rename', 20000
      .click                     'li.rename'
      .waitForElementVisible     'li.selected .rename-container .hitenterview', 20000
      .clearValue                'li.selected .rename-container .hitenterview'
      .setValue                  'li.selected .rename-container .hitenterview', newFileName + '\n'
      .waitForElementPresent     newFileSelector, 20000 # Assertion
      .end()


  checkMachine: (browser) ->

    user = helpers.beginTest(browser)

    ideModalSelector   = '.ide-modal.ide-machine-state'
    turnOnButton       = '.turn-on.state-button'
    progressBar        = '.progressbar-container'
    stateLabelSelector = ideModalSelector + ' .state-label'

    browser
      .pause 3000 # wait to see ide modal
      .element 'css selector', ideModalSelector, (result) =>

        if result.status is 0 # ide modal found
          browser
            .waitForElementNotPresent ideModalSelector + '.checking', 30000
            .getText stateLabelSelector, (result) =>
              label = result.value

              if label.indexOf('turned off') > -1
                console.log 'machine turned off, turning on'

                browser
                  .waitForElementVisible      turnOnButton, 30000
                  .click                      turnOnButton
                  .waitForElementVisible      progressBar, 20000
                  .waitForElementNotVisible   ideModalSelector, 120000 # Assertion
                  .end()

              else if label.indexOf('building') is -1 or label.indexOf('starting') is -1
                console.log 'machine is building/starting, waiting up to 2.5 min for assertion'

                browser.waitForElementNotVisible ideModalSelector, 120000 # Assertion
                browser.end()

        else # machine is already turned on
          console.log 'machine is already running'


  duplicate: (browser) ->

    user          = helpers.beginTest(browser)
    filename      = helpers.createFile(browser, user)
    newFileName   = filename.split('.txt').join('_1.txt')
    webPath       = '/home/' + user.username + '/Web'
    fileSelector  = "span[title='" + webPath + '/' + filename + "']"
    newFile       = "span[title='" + webPath + '/' + newFileName + "']"

    browser
      .waitForElementPresent     fileSelector, 20000
      .click                     fileSelector
      .click                     fileSelector + ' + .chevron'
      .waitForElementVisible     'li.duplicate', 20000
      .click                     'li.duplicate'
      .pause                     2000
      .waitForElementPresent     newFile, 20000 # Assertion
      .end()


  collapse: (browser) ->

    user        = helpers.beginTest(browser)
    webPath     = '/home/' + user.username + '/Web'
    webSelector = "span[title='" + webPath + "']"
    file        = "span[title='" + webPath + '/' + 'index.html' + "']"

    helpers.openFolderContextMenu(browser, user, 'Web')

    browser
      .waitForElementVisible    '.expand', 20000
      .click                    '.expand'
      .pause                    2000 # required
      .waitForElementVisible    webSelector, 20000
      .click                    webSelector + ' + .chevron'
      .waitForElementVisible    '.collapse', 20000
      .click                    '.collapse'
      .waitForElementNotPresent file, 20000 # Assertion
      .end()


  makeTopFolder: (browser) ->

    user           = helpers.beginTest(browser)
    webPath        = '/home/' + user.username + '/Web'
    filename       = helpers.createFile(browser, user)
    webSelector    = "span[title='" + webPath + "']"
    fileSelector   = "span[title='" + webPath + '/' +filename + "']"
    selectMenuItem = 'li.home'+user.username

    browser
      .waitForElementPresent   fileSelector, 20000 # Assertion
      .waitForElementVisible   webSelector, 10000
      .click                   webSelector
      .click                   webSelector + ' + .chevron'
      .waitForElementVisible   '.make-this-the-top-folder', 20000
      .click                   '.make-this-the-top-folder'
      .waitForElementVisible   '.vm-info', 20000
      .assert.containsText     '.vm-info', '~/Web'
      .waitForElementPresent   fileSelector, 20000 # Assertion

    helpers.openChangeTopFolderMenu(browser)

    browser
      .waitForElementVisible   selectMenuItem, 20000
      .click                   selectMenuItem
      .pause                   2000 # required
      .end()


  createWorkspaceFromVmList: (browser) ->

    user          = helpers.beginTest(browser)
    paragraph     = helpers.getFakeText()
    workspaceName = paragraph.split(' ')[0]

    browser
      .waitForElementVisible   '.kdscrollview li a.more-link', 20000
      .click                   '.kdscrollview li a.more-link'
      .waitForElementVisible   '.kdmodal-inner', 20000
      .click                   '.kdmodal-inner button'
      .pause 2000 # required
      .waitForElementVisible   '.add-workspace-view', 20000
      .setValue                '.add-workspace-view input.kdinput.text', workspaceName + '\n'
      .waitForElementVisible   '.vm-info', 20000
      .pause 2000, =>

        browser.url (data) =>
          url    = data.value
          vmName = url.split('/IDE/')[1].split('/')[0]

          browser
            .assert.urlContains      workspaceName # Assertion
            .assert.containsText     '.vm-info', '~/Workspaces/' + workspaceName # Assertion
            .waitForElementPresent   'a[href="/IDE/' + vmName + '/' + workspaceName + '"]', 20000 # Assertion
            .end()
