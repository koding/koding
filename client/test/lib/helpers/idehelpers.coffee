helpers           = require './helpers.js'
utils = require '../utils/utils.js'
panelSelector     = '.pane-wrapper .kdsplitview-panel.panel-1'
tabHandleSelector = "#{panelSelector} .application-tab-handle-holder"
activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active'
filesTabSelector    = '.ide-files-tab .file-container'
packageInstallerModal = '.kdmodal-inner'
installPackageButton = '[testpath=proceed]'
successModal          = '.kdmodal-inner .kdmodal-content'
closeButton           = '.ContentModal.kdmodal .kdmodal-inner .close-icon'

module.exports =

  openNewFile: ( browser, callback = -> ) ->

    @closeAllTabs browser

    browser.elements 'css selector', successModal, (result) ->
      if result.value.length
        browser
          .waitForElementVisible '.ContentModal.content-modal header > h1', 20000
          .waitForElementVisible closeButton,  20000
          .click closeButton

    activeEditorSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .kdtabpaneview.active .ace_content'
    plusSelector         = tabHandleSelector + ' .visible-tab-handle.plus'

    browser
      .waitForElementVisible  plusSelector, 20000
      .click                  plusSelector
      .waitForElementVisible  '.kdlistview-contextmenu li.new-file', 20000
      .click                  '.kdlistview-contextmenu li.new-file'
      .waitForElementVisible  activeEditorSelector, 20000, false, -> callback() # Assertion


  closeAllTabs: (browser) ->

    # there is a firefox related snapshot restore issue therefore a refresh and
    # a pause is needed here. it only happens in firefox because firefox has
    # some serious focus issues this is just a hacky workaround for now.
    browser
      .refresh()
      .pause 7500

    handleSelector = '.panel-1 .pane-wrapper .kdtabhandle.kddraggable'
    modalSelector  = '.autoremovepane-confirm'

    doClose = ->
      browser
        .moveToElement handleSelector, 5, 5
        .click         handleSelector + ' .close-tab'
        .pause         500 # wait for modal
        .element       'css selector', modalSelector, (result) ->
          if result.status is 0
            browser
              .click   "#{modalSelector} .kdbutton.red"
              .pause   500

    close = ->
      browser.elements 'css selector', handleSelector, (result) ->
        if result.value.length isnt 0 then doClose()

    close()


  openContextMenu: ( browser, callback = -> ) ->

    fileSelector    = "#{tabHandleSelector} .kdtabhandle.active"
    optionsSelector = "#{fileSelector} span.options"
    browser
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 60, 17
      .moveToElement          optionsSelector, 8, 8
      .waitForElementVisible  optionsSelector, 20000
      .click                  optionsSelector
      .waitForElementVisible  '.kdlistview-contextmenu', 50000
      .pause 2000, ->
        callback() # Assertion


  createAndSaveNewFile: (browser, user, text, callback) ->

    saveSelector        = '.kdlistview-contextmenu li.save'
    saveAsModalSelector = '.save-as-dialog'
    saveAsInputSelector = "#{saveAsModalSelector} input[type=text]"
    newName             = helpers.getFakeText().split(' ')[0] + '.txt'
    titleSelector       = "div[title='/home/#{user.username}/#{newName}']"
    saveButtonSelector  = "#{saveAsModalSelector} .kdbutton.GenericButton.primary"
    text                ?= 'For example'
    closeSelector       = '.ContentModal.content-modal footer .kdbutton.cancel'

    @openNewFile(browser)

    if text
      @setTextToEditor browser, text

    @openContextMenu(browser)

    browser
      .waitForElementVisible  saveSelector, 20000
      .pause 5000
      .click                  saveSelector
      .waitForElementVisible  saveAsModalSelector, 20000
      .waitForElementVisible  saveAsInputSelector, 20000
      .clearValue             saveAsInputSelector
      .setValue               saveAsInputSelector, newName
      .click                  saveButtonSelector
      .waitForElementVisible  "#{tabHandleSelector} #{titleSelector}", 20000 # Assertion
      .waitForElementVisible  filesTabSelector, 20000
      .assert.containsText    filesTabSelector, newName # Assertion

    browser.pause 10, -> callback()

    return newName


  setTextToEditor: (browser, text) ->

    browser.execute "_kd.singletons.appManager.frontApp.activeTabView.activePane.view.setContent('#{text}')"


  saveFile: (browser) ->

    saveSelector      = '.kdlistview-contextmenu li.save'
    saveIconSelector  = "#{tabHandleSelector} .modified"

    @openContextMenu(browser)

    browser
      .waitForElementVisible    saveSelector, 20000
      .click                    saveSelector
      .waitForElementNotPresent saveIconSelector, 20000 # Assertion


  saveAsFile: (browser) ->

    saveAsSelector     = '.kdlistview-contextmenu li.save-as'
    saveIconSelector = "#{tabHandleSelector} .modified"
    saveAsDialog     = 'body.ide .kddialogview.save-as-dialog'
    inputTxt = 'body.ide .kddialogview.save-as-dialog form .kdinput'
    host = utils.getUser no, 0

    @openContextMenu(browser)

    browser
      .waitForElementVisible    saveAsSelector, 20000
      .click                    saveAsSelector
      .waitForElementPresent    saveAsDialog, 20000
      .clearValue               inputTxt
      .setValue                 inputTxt, [browser.Keys.COMMAND, 'a', browser.Keys.BACK_SPACE]
      .setValue                 inputTxt, 'newFile.txt'
      .pause                    2000
      .click                    '.kdbutton.green', ->
        browser
          .pause 3000
          .waitForElementNotPresent    saveAsDialog, 20000
          .refresh()
          .waitForElementVisible '.kdlistitemview-finderitem:last-child', 40000

          .waitForElementVisible  "span[title='/home/#{host.username}/newFile.txt']", 20000
          .assert.containsText  '.kdlistitemview-finderitem:last-child > div .title', 'newFile.txt'


  closeFile: (browser, fileName, user) ->

    closeFileSelector = "#{tabHandleSelector} span.close-tab"
    browser
      .moveToElement             tabHandleSelector, 60, 15
      .waitForElementVisible     closeFileSelector, 20000
      .click                     closeFileSelector
      .waitForElementNotPresent  "#{tabHandleSelector} div[title='/home/#{user.username}/#{fileName}']", 20000 # Assertion


  openAnExistingFile: (browser, user, fileName, text) ->

    fileSelector        = "#{filesTabSelector} span[title='/home/#{user.username}/#{fileName}']"
    fileChevronSelector = "#{fileSelector} + .chevron"

    browser
      .waitForElementVisible  filesTabSelector, 20000
      .pause                  3000
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 70, 12
      .waitForElementVisible  fileChevronSelector, 20000
      .click                  fileChevronSelector
      .waitForElementVisible  'li.open-file', 20000
      .click                  'li.open-file'
      .pause                  3000 # wait for tabHandle
      .waitForElementVisible  "#{tabHandleSelector} div[title='/home/#{user.username}/#{fileName}']", 20000 # Assertion
      .assert.containsText    activeEditorSelector, text # Assertion


  openFileFromConfigFolder: ( browser, user, fileName, fileContent, callback = -> ) ->

    fileName    or= 'index.html'
    fileContent or= 'Hello World from HTML by Koding'
    fileSelector  = "span[title='/home/#{user.username}/.config/#{fileName}']"
    fileNameSlug  = fileName.replace '.', ''
    tabSelector   = ".kdtabpaneview.#{fileNameSlug}.active"

    helpers.openFolderContextMenu browser, user, '.config'
    browser
      .waitForElementVisible   'li.expand', 15000
      .click                   'li.expand'
      .waitForElementVisible   fileSelector, 15000
      .click                   fileSelector
      .click                   fileSelector + ' + .chevron'
      .waitForElementVisible   'li.open-file', 20000
      .click                   'li.open-file'
      .waitForElementVisible   ".pane-wrapper .kdsplitview-panel .#{fileNameSlug}", 20000 # Assertion
      .waitForElementVisible   tabSelector, 20000 # Assertion
      .waitForTextToContain    tabSelector, fileContent # Assertion
      .pause 10, -> callback()

  openFile: ( browser, user, fileName, callback = -> ) ->
    filePath            = "/home/#{user.username}/.config/#{fileName}"
    fileSelector        = "span[title='#{filePath}']"
    chevronSelector     = "#{fileSelector} + span.chevron"
    contextMenuSelector = '.kdlistview-contextmenu'
    openFileSelector    = "#{contextMenuSelector} li.open-file"
    fileTabSelector     = "div[title='#{filePath}']"

    browser
      .waitForElementVisible  fileSelector, 20000
      .moveToElement          fileSelector, 120, 12
      .click fileSelector
      .waitForElementVisible  chevronSelector, 20000
      .click                  chevronSelector
      .waitForElementVisible  contextMenuSelector, 20000
      .click                  openFileSelector
      .waitForElementVisible  fileTabSelector, 20000, false, -> callback()


  clickItemInMachineHeaderMenu: (browser, selector) ->

    helpers.clickVMHeaderButton(browser)
    browser.click ".context-list-wrapper #{selector}"


  compressFileFolder: ( browser, user, type, fileFolderName, compressType, callback = -> ) ->

    configPath     = '/home/' + user.username + '/.config'
    name        = fileFolderName

    if type is 'folder'
      configPath   = '/home/' + user.username
      name      = fileFolderName.name

    fileFolderSelector  = "span[title='" + configPath + '/' + name + "']"
    submenuSelector     = "li.as-#{compressType}"
    extension           = '.zip'

    if compressType is 'targz'
      extension = '.tar.gz'

    newFile = "span[title='" + configPath + '/' + name + extension + "']"

    browser
      .waitForElementPresent     fileFolderSelector, 20000
      .click                     fileFolderSelector
      .click                     fileFolderSelector + ' + .chevron'
      .waitForElementVisible     'li.compress', 20000
      .click                     'li.compress'
      .waitForElementVisible     submenuSelector, 20000
      .click                     submenuSelector
      .pause                     2000

    # install zip package if it is not exist
    browser.element 'css selector', packageInstallerModal, (result) =>
      if result.status is 0
        @installZipPackage browser, fileFolderSelector, submenuSelector, =>
          browser.element 'css selector', packageInstallerModal, (result) =>
            if result.status is 0
              @installZipPackage browser, fileFolderSelector, submenuSelector, ->

    @waitNewFile browser, newFile, fileFolderSelector, ->
      callback()
    # browser.waitForElementPresent newFile, 50000 # Assertion

    # helpers.deleteFile browser, fileFolderSelector , ->
    #   helpers.deleteFile browser, newFile, -> callback()

  installZipPackage: (browser, fileFolderSelector, submenuSelector, done) ->
    browser.element 'css selector', packageInstallerModal, (result) ->
      if result.status is 0
        browser
          .waitForElementVisible packageInstallerModal, 2000
          .waitForElementVisible installPackageButton, 20000
          .click installPackageButton
          .pause 10000
          .waitForElementPresent     fileFolderSelector, 20000
          .click                     fileFolderSelector
          .click                     fileFolderSelector + ' + .chevron'
          .waitForElementVisible     'li.compress', 20000
          .click                     'li.compress'
          .waitForElementVisible     submenuSelector, 20000
          .click                     submenuSelector
          .pause                     2000, done

  waitNewFile: (browser, newFile, fileFolderSelector, done) ->
    browser.element 'css selector', newFile, (result) ->
      if result.status is 0
        browser.waitForElementPresent newFile, 20000
        helpers.deleteFile browser, fileFolderSelector , ->
          helpers.deleteFile browser, newFile, -> done
      else
        @waitNewFile browser, newFile, done

  #Will be reimplement
  # dragDropFile: (browser, fileName) ->
  #   user = utils.getUser()
  #   filePath            = "/home/#{user.username}/.config/#{fileName}"
  #   fileSelector        = "span[title='#{filePath}']"
  #   dropFilePath        = '.vm'

  #   paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1 .application-tab-handle-holder'
  #   tabSelector  = '.kdtabhandle.terminal:nth-of-type(2)'

  #   # helpers.openFolderContextMenu(browser, user, '.config')

  #   browser
  #     .pause   4000
  #     .waitForElementVisible    tabSelector, 20000
  #     .waitForElementVisible    paneSelector, 20000
  #     .waitForElementVisible    '.kdtabhandle.plus:nth-of-type(1)', 20000
  #     .moveToElement            tabSelector, 20, 3
  #     .mouseButtonDown 0
  #     .pause 2000
  #     .moveToElement           '.kdtabhandle.plus:nth-of-type(1)',  0,  0
  #     .mouseButtonUp 0
  #     .pause 5000
