nginx = require './NginxApi'

__resReport = (error,result,callback)->
  if error
    callback? error
  else
    callback? null,result


nginxKites =

  addVhost : (options,callback)->

    # add koding vhost to nginx proxy configuration

    # options =
    #   backendSubdomain  : String # Koding subdomain <username>.koding.com (<subdomain>.koding.com) or user defined domain (example.com)
    #   backendServerAddr : String # backend server address (FQDN - cl0.dev.srv.kodingen.com ... cl100.dev.srv.koding.com)
    #

    nginx.addMapRecord options,(error,result)->
      __resReport(error,result,callback)

  deleteVhost : (options,callback)->

    # delete koding vhost from nginx proxy configuration

    # options =
    #   backendSubdomain : String # Koding subdomain <username>.koding.com (<subdomain>.koding.com) or user defined domain (example.com)

    nginx.removeMapRecord options,(error,result)->
      __resReport(error,result,callback)

module.exports = nginxKites
