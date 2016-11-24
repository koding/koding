$ = require 'jquery'

module.exports = (expect) ->

  # select finder item for `.bash_rc`
  fileItemSelector = 'span[title*=bash_rc]'

  $el = $(fileItemSelector)

  expect($el.text()).toBe '.bash_rc'
