generateStopInterval = (interval) -> -> clearInterval interval

module.exports = (browser, machineName) ->

  unless machineName
    machineName = 'koding-vm-0'

  vmSelector     = ".#{machineName} .running.vm"
  modalSelector  = '.env-modal.env-machine-state'
  buildingLabel  = modalSelector + ' .state-label.building'
  turnOnButtonSelector = modalSelector + ' .turn-on.state-button'

  browser.element 'css selector', vmSelector, (result) ->
    if result.status is 0
      console.log ' ✔ VM is running'
      browser.waitForElementNotPresent  modalSelector, 50000
    else
      console.log ' ✔ VM is not running'
      browser
        .waitForElementVisible   modalSelector, 50000
        .element 'css selector', buildingLabel, (result) ->
          if result.status is 0
            console.log ' ✔ VM is building, waiting to finish'

            browser
              .waitForElementNotPresent  modalSelector, 600000
              .pause                     5000 # wait for sidebar redraw

            logProgress = setInterval ->
              console.log '   VM is still building'
            , 30000

            stopInterval = generateStopInterval logProgress

            browser
              .waitForElementVisible vmSelector, 20000, stopInterval
              .pause 10000, stopInterval

          else
            console.log ' ✔ VM turn on button is clicked, waiting to turn on'

            browser
              .waitForElementVisible     turnOnButtonSelector, 100000
              .click                     turnOnButtonSelector

            logProgress = setInterval ->
              console.log '   VM is still turning on'
            , 30000

            stopInterval = generateStopInterval logProgress

            browser
              .waitForElementNotPresent  modalSelector, 600000, stopInterval
              .pause                     5000 # wait for sidebar redraw
              .waitForElementVisible     vmSelector, 20000, stopInterval
              .pause 10000, stopInterval
