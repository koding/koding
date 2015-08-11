module.exports =

  ctrlAltKey(browser,key) ->

    browser
      .keys browser.Keys.CONTROL
      .keys browser.Keys.ALT
      .keys key

  cmdAltShiftKey(browser,key) ->

    browser
      .keys browser.Keys.COMMAND
      .keys browser.Keys.ALT
      .keys browser.Keys.SHIFT
      .keys key

  cmdKey(browser,key) ->

    browser
      .keys browser.Keys.COMMAND
      .keys key
