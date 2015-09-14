helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'


module.exports =


  createSnapshot: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.createSnapshot(browser)
    browser.end()


  renameSnapshot: (browser) ->

    contentSelector  = '.snapshots.AppModal-content'
    snapshotSelector = '.snapshots .kdlistitemview-snapshot:first-child'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    environmentHelpers.openSnapshotsSettings(browser)

    browser.pause 5000 # wait for snapshot to load

    browser.getText contentSelector, (result) ->
      if result.value.indexOf('renamed-snapshot') > -1
        console.log ' ✔ Snapshot is already renamed. Ending test...'
        browser.end()
      else
        browser.element 'css selector', snapshotSelector, (result) ->
          if result.status is 0
            renamed = environmentHelpers.renameSnapshot(browser)
            environmentHelpers.assertSnapshotPresent browser, renamed, false

          else
            browser.pause 3000
            environmentHelpers.addSnapsButton(browser)
            environmentHelpers.createSnapshot(browser, no)
            renamed = environmentHelpers.renameSnapshot(browser)
            environmentHelpers.assertSnapshotPresent browser, renamed, false

        browser.end()


  deleteSnapshot: (browser) ->

    snapshotListSelector = '.snapshots .listview-wrapper'
    snapshotSelector = '.snapshots .kdlistitemview-snapshot:first-child'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    environmentHelpers.openSnapshotsSettings(browser)

    browser.element 'css selector', snapshotSelector, (result) ->
      if result.status is 0
        browser.getText "#{snapshotSelector} .label", (result) ->
          snapshotName = result.value
      else
        snapshotName = environmentHelpers.createSnapshot(browser)

      environmentHelpers.deleteSnapshot(browser)

      browser
        .pause 3000
        .waitForElementVisible     snapshotListSelector, 20000
        .waitForElementNotPresent  "#{snapshotListSelector} .info .label.#{snapshotName}", 20000
        .end()
