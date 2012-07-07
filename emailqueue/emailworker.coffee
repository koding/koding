{fork} = require 'child_process'

module.exports = class EmailWorker

  constructor:(@config)->
    flags = ['-p', config.postmark.apiKey, '--sharedHosting']
    @child = fork './emailworker/worker', flags

  handleNotification:(notification, user, callback)-> 
    @child.send {notification, user}
    @child.once 'message', (message)=>
      switch message
        when 'FINISHED' then callback null
        else
          callback new Error 'Really bad error.  Seriously.'
  
  kill:-> @child.kill()