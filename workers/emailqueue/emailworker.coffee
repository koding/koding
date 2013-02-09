{EventEmitter} = require 'events'
{fork} = require 'child_process'

module.exports = class EmailWorker extends EventEmitter

  constructor:(@config)->
    flags = ['-p', config.postmark.apiKey, '--sharedHosting']
    @child = fork './emailworker/worker', flags

  handleNotification:(notification, user, callback)->
    @child.send {notification, user}
    @child.once 'message', (message)=>
      switch message
        when 'ATTEMPTING'   then @emit 'SendAttempt', notification
        when 'FINISHED'     then callback null
        else
          callback new Error 'Really bad error.  Seriously.'

  kill:-> @child.kill()