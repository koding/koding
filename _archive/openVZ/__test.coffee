ovz = require './openVzKites'

goodVz0 =
  name     : 'helloworld0'+Date.now()
  #template  : tempalate
  password : 'v(dhDF)3P]9&="bxHa'
  ram      : 512
  swap     : 512
  cpulimit : 500
  cpus     : 1
  diskspace: 10

limits =
  password : 'v(dhDF)3P]9&="bxHa'
  ram      : 512
  swap     : 512
  cpulimit : 500
  cpus     : 1
  diskspace: 10




ovz.fetchPublicTemplates (error,result)->
  if error?
    console.error error
  else
    console.info "creating container from template #{result[1]}"
    goodVz0.template = result[1]
    ovz.createContainer goodVz0,(error,result)->
      if error?
        console.error error
      else
         console.info result
         ctID = result.ctID
         ipaddr = result.ipaddr
         limits.ctID = ctID
         ovz.modifyContainerLimits limits,(error,result)->
          if error?
            console.error error
          else
            console.info result
            console.log "ID #{ctID}"
            ovz.fetchContainerProcesses ctID:ctID ,(error,result)->
              if error?
                console.error error
              else
                console.info result
                ovz.destroyContainer ctID:ctID,ipaddr:ipaddr,fast:true,(error,result)->
                  if error?
                    console.error error
                  else
                    console.log result


