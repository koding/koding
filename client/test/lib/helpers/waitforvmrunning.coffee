module.exports = (browser, machineName) ->

  unless machineName
    machineName = 'koding-vm-0'

  vmSelector     = ".#{machineName} .running.vm"
  modalSelector  = '.env-modal.env-machine-state'
  loaderSelector = modalSelector + ' .kdloader'
  buildingLabel  = modalSelector + ' .state-label.building'
  turnOnButtonSelector = modalSelector + ' .turn-on.state-button'

  browser.element 'css selector', vmSelector, (result) =>
    if result.status is 0
      console.log '✔  VM is running'
      browser.waitForElementNotVisible  modalSelector, 50000
    else
      console.log '✔  VM is not running'
      browser
        .waitForElementVisible   modalSelector, 50000
        .element 'css selector', buildingLabel, (result) =>
          if result.status is 0
            console.log '✔  VM is building, waiting to finish'
            browser
              .waitForElementNotVisible  modalSelector, 200000
              .waitForElementVisible     vmSelector, 20000
              .pause 10000

          else
            console.log '✔  VM turn on button is clicked, waiting to turn on'

            browser
              .waitForElementVisible     turnOnButtonSelector, 20000
              .click                     turnOnButtonSelector
              .waitForElementNotVisible  modalSelector, 200000
              .waitForElementVisible     vmSelector, 20000
              .pause 10000
