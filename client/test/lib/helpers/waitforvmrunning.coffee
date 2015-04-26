module.exports = (browser, machineName) ->

  unless machineName
    machineName = 'koding-vm-0'

  vmSelector     = ".#{machineName} .running.vm"
  modalSelector  = '.env-modal.env-machine-state'
  loaderSelector = modalSelector + ' .kdloader'
  buildingLabel  = modalSelector + ' .state-label.building'
  turnOnButtonSelector = modalSelector + ' .turn-on.state-button'

  # browser.element 'css selector', vmSelector, (result) =>
  browser.waitForElementVisible vmSelector, 50000, false, (result) =>
    if result.status is 0
      console.log 'vm is running'
      browser.waitForElementNotVisible  modalSelector, 500000, false
    else
      console.log 'vm is not running'
      browser
        .waitForElementVisible   modalSelector, 50000
        .element 'css selector', buildingLabel, (result) =>
          if result.status is 0
            console.log 'vm is building, waiting to finish'
            browser
              .waitForElementNotVisible  modalSelector, 500000
              .waitForElementVisible     vmSelector, 500000
              # .pause 10000

          else
            console.log 'turn on button is clicked, waiting for VM turn on'

            browser
              .waitForElementVisible     turnOnButtonSelector, 500000
              .click                     turnOnButtonSelector
              .waitForElementNotVisible  modalSelector, 500000
              .waitForElementVisible     vmSelector, 500000
              # .pause 10000
