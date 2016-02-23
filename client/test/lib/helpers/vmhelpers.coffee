utils    = require '../utils/utils.js'
fail     = require '../utils/fail.js'
register = require '../register/register.js'
faker    = require 'faker'
assert   = require 'assert'


module.exports =

  acceptInvitation: (browser, firstUser, secondUser) ->

    firstUserName    = firstUser.username
    secondUserName   = secondUser.username
    shareModal       = '.share-modal'
    fullName         = shareModal + ' .user-details .fullname'
    acceptButton     = shareModal + ' .kdbutton.green'
    selectedMachine  = '.shared-machines .sidebar-machine-box'
    openMachine      = "#{selectedMachine} .running"

    browser
      .waitForElementVisible     shareModal, 500000 # wait for vm turn on for host
      .waitForElementVisible     fullName, 50000
      .assert.containsText       shareModal, firstUserName
      .waitForElementVisible     acceptButton, 50000
      .click                     acceptButton
      .waitForElementNotPresent  shareModal, 50000
      .pause                     3000 # wait for sidebar redraw
      .waitForElementVisible     openMachine, 20000 # Assertion


  clickAddUserButton: (browser) ->

    vmSharingListSelector = '.vm-sharing.active'
    addUserButtonSelector = "#{vmSharingListSelector} .kdheaderview .green"

    browser
      .waitForElementVisible  vmSharingListSelector, 20000
      .waitForElementVisible  addUserButtonSelector, 20000
      .click                  addUserButtonSelector