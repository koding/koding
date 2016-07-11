kd                     = require 'kd'
whoami                 = require 'app/util/whoami'
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'
fetchIntercomKey       = require 'app/util/fetchIntercomKey'

module.exports = setupIntercom = ->

  fetchIntercomKey (intercomId) ->
    return  unless intercomId

    w  = window
    ic = w.Intercom

    if typeof ic is 'function'
      ic 'reattach_activator'
      ic 'update', w.intercomSettings ? {}
    else
      d = document
      i = -> i.c arguments
      i.q = []
      i.c = (args) -> i.q.push args
      w.Intercom = i
      w.intercomSettings = { app_id : intercomId }

      s = d.createElement 'script'
      s.type  = 'text/javascript'
      s.async = yes
      s.src = "https://widget.intercom.io/widget/#{intercomId}"
      x = d.getElementsByTagName('script')[0]
      x.parentNode.insertBefore s, x

      account = whoami()
      account.fetchEmail (err, email) ->
        window.Intercom 'boot',
          app_id : intercomId
          name   : getFullnameFromAccount account
          email  : email
