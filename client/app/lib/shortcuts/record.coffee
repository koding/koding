$ = require 'jquery'
_ = require 'lodash'
keycode = require 'keycode'

MAX_KEYS = 5
WAIT_MS  = 1000

seq  = []
next = null
pending = null
running = no


done = ->

  next? _.uniq seq
  reset()

  return


reset = ->

  $(document).off 'keydown', record
  clearTimeout pending
  seq  = []
  next = null
  running = no

  return


record = (e) ->

  e.preventDefault()
  e.stopPropagation()

  clearTimeout pending

  code = e.which or e.keyCode
  key  = keycode code

  if seq.push(key) > (MAX_KEYS - 1)
  then done()
  else pending = setTimeout done, WAIT_MS


module.exports = (cb) ->

  if running then reset()
  running = yes
  next = cb
  $(document).on 'keydown', record

  return
