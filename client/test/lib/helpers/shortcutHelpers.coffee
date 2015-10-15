module.exports =

  ctrlAltKey: (browser,key) ->

    browser
      .keys browser.Keys.CONTROL
      .keys browser.Keys.ALT
      .keys key
      .keys browser.Keys.ALT
      .keys browser.Keys.CONTROL

  cmdAltShiftKey: (browser,key) ->

    browser
      .keys browser.Keys.COMMAND
      .keys browser.Keys.ALT
      .keys browser.Keys.SHIFT
      .keys key
      .keys browser.Keys.SHIFT
      .keys browser.Keys.ALT
      .keys browser.Keys.COMMAND

  cmdKey: (browser,key) ->

    browser
      .keys browser.Keys.COMMAND
      .keys key
      .keys browser.Keys.COMMAND

  escape: (browser) ->

    browser
      .keys  browser.Keys.ESCAPE
      .pause 10
      .keys  browser.Keys.ESCAPE
