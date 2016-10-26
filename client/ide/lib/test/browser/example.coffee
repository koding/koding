$ = require 'jquery'

module.exports = (expect) ->

  # select finder item for `.bash_rc`
  fileItemSelector = 'kdlistitemview-finderitem span[title~=bash_rc]'

  $el = $(fileItemSelector)

  expect($el.val()).toBe '.bash_rc'
