# this is converted with js2coffee
# original needs to be put here - SY

util = require('util')
events = require('events')

WaitForTextToContain = ->
  events.EventEmitter.call this
  @startTimeInMilliseconds = null
  return

util.inherits WaitForTextToContain, events.EventEmitter

WaitForTextToContain::command = (element, textToContain, timeoutInMilliseconds) ->
  @startTimeInMilliseconds = (new Date).getTime()
  self = this
  message = undefined
  unless timeoutInMilliseconds
    timeoutInMilliseconds = 20000

  checkerFn = (content) ->
    content.indexOf(textToContain) > -1

  @check element, checkerFn, ((result, loadedTimeInMilliseconds) ->
    if result
      message = 'Element <' + element + '> contains text "' + textToContain + '" in ' + loadedTimeInMilliseconds - (self.startTimeInMilliseconds) + ' ms.'
    else
      message = 'Element <' + element + '> wasn\'t contains text "' + textToContain + '" in ' + timeoutInMilliseconds + ' ms.'
    self.client.assertion result, 'expression false', 'expression true', message, true
    self.emit 'complete'
    return
  ), timeoutInMilliseconds
  this

WaitForTextToContain::check = (element, checker, callback, maxTimeInMilliseconds) ->
  self = this
  @api.getText element, (result) ->
    now = (new Date).getTime()
    if result.status is 0 and checker(result.value)
      callback true, now
    else if now - (self.startTimeInMilliseconds) < maxTimeInMilliseconds
      setTimeout (->
        self.check element, checker, callback, maxTimeInMilliseconds
        return
      ), 300
    else
      callback false
    return
  return

module.exports = WaitForTextToContain
