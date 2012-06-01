ovz = require './openVzApi'




__resReport = (error,result,callback)->
  if error
    callback error
  else
    callback null,result


openVzKites =

  fetchPublicTemplates : (callback)->

    # get array of available templates

    ovz.fetchTemplates (error,result)->
      __resReport(error,result,callback)

  createContainer : (options,callback)->

    # create OpenVZ container

    #
    # options =
    #   node      : String # hardware node FQDN
    #   name      : String # name for container
    #   template  : String # template name
    #   password  : String # root password
    #   ram       : Number # RAM for container in MB
    #   swap      : Number # Swap in MB (512 mb is good in most cases)
    #   cpulimit  : Number # Max Mhz available for container
    #   cpus      : Number # sets number of CPUs available in the container
    #   diskspace : Number # disk quota limit in GB
    #

    ovz.createCT options,(error,result)->
      if error?
        callback? error
      else
        options.ctID   = result.id
        options.ipaddr = result.ip
        ovz.setCTparams options,(error,result)->
          if error?
            callback? error
          else
            ovz.bootCT options,(error,result)->
              if error?
                callback? error
              else
                callback? null,result

  destroyContainer : (options,callback)->

    # destroy OpenVZ container

    # options =
    #   ctID   : Number # container ID
    #   ipaddr : String # IP address for container
    #   fast   : Boolean # fast makes use reboot(2) syscall which is faster but
    #                    # can lead to unclean container shutdown, so this param should be used for the destruction of the container
    #

    ovz.haltCT options,(error,result)->
      if error?
        callback? error
      else
        ovz.destroyCT options,(error,result)->
          if error?
            callback? error
          else
            callback null,result

  modifyContainerLimits : (options,callback)->


    #
    # modify main container limits
    #

    #
    # can be any of the parameters or all at once
    #
    # options =
    #   ctID      : Number # container ID, from createCT method
    #   password  : String # root password
    #   ram       : Number # RAM for container in MB
    #   swap      : Number # Swap in MB (512 mb is good in most cases)
    #   cpulimit  : Number # Max Mhz available for container
    #   cpus      : Number # sets number of CPUs available in the container
    #   diskspace : Number # disk quota limits in GB
    #

    ovz.modifyCT options,(error,result)->
      __resReport(error,result,callback)

  fetchContainerProcesses : (options,callback)->

    #
    # fetch all running processes inside container
    #

    #
    # options =
    #   ctID : Number # container ID, from createCT method
    #

    ovz.fetchCTprocesses options,(error,result)->
      __resReport(error,result,callback)

module.exports = openVzKites



