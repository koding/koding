http  = require 'http'
xml   = require 'xml2json'
url   = require 'url'



# configuration

config =
  ctNameserver0 : '172.16.0.23' # nameserver for containers
  #ctNameserver1 : '10.0.80.12'
  baseDomain    : '.vm.koding.com'
  tempateDir    : '/vz/template/cache/'
  api:
    host: 'ovzmgt.beta.system.aws.koding.com'
    port: 3000
    user: 'api_admin'
    pass: 'PnAXY[*2IyO^+8,o'
    defaultPass: 'VcGadsd333rffff' # default pass for all users
    defaultMail: 'system@koding.com'
    defaultContact: 'Koding'

class OpenVZ


  sendRequest : (options,callback)->
    
    #
    # options =
    #   user: 
    #   pass:
    #   req : api request

    {user,pass,req} = options
    console.log "#{url.format req}"
    console.log options
    
    options = 
      host : config.api.host
      auth: "#{user}:#{pass}"
      port: 3000
      path : "#{url.format req}"

    req = http.get options, (res)->
      responseText = ''
      res.on 'data', (chunk) ->
        responseText += chunk

      res.on 'end',()->
        console.log responseText
        jsonedResponse = JSON.parse(xml.toJson "#{responseText}")
        if jsonedResponse.result?.status?.$t == 'false'
          callback jsonedResponse
        else
          callback null,jsonedResponse

    req.on 'error', (e)->
      console.log  e.message
      callback e.message


  createUser : (options,callback) ->
    
    # create containers owner
    
    # options =
    #   username # koding username

    
    api_request =
      pathname: "/api/users/create"
      query:
        login: options.username
        password: config.api.defaultPass
        contact_name: options.username
        email:  options.username + '@koding.com'
        role_id : 2 # virtual server owner
    
    options =
      req : api_request
      user: config.api.user
      pass: config.api.pass

    @sendRequest options,(error,result)->
      if error?
        callback error
      else
        callback null, result

  fetchUserID : (options, callback)->
    
    # username
    api_request =
      pathname: '/api/users/list'


    options =
      req : api_request
      user: config.api.user
      pass: config.api.pass
      username: options.username

    @sendRequest options, (error,result)->
      if error?
        callback error
      else
        userFound = false
        result.users.user.forEach (user)->
          if user.login is options.username
            userFound = true
            callback null,user.id.$t
        unless userFound
          callback error:"can't find user id for #{options.username}"
        


  fetchServers : (options, callback)->

    # fetch username's containers

    # username

    api_request =
      pathname: '/api/virtual_servers/own_servers'
    
    options =
      req: api_request
      user: options.username
      pass: config.api.defaultPass

    @sendRequest options,(error,result)->
      if error?
        callback error
      else
        callback null,result.virtual_servers.virtual_server


  
  createServer : (options, callback)->
    
    # create container

    # username
    # hardware_server_id
    # os_template
    # vmtype : vswap-2g, vswap-4g, vswap-1g
    # hostname
    # password
    # expiration_date : like 2012.07.30
    # diskspace # in gb

    @fetchUserID username:options.username, (err,res)=>
      if err?
        callback err
      else
        api_request =
          pathname: '/api/virtual_servers/create'
          query:
            hardware_server_id: 1
            orig_os_template : options.os_template
            orig_server_template: options.vmtype
            host_name: options.hostname
            password: options.password
            expiration_date: options.expiration_date
            nameserver: config.ctNameserver0
            start_on_boot: 'true'
            ip_address: 'auto'
            user_id : res
            diskspace: options.diskspace*1024

        options =
          req : api_request
          user: config.api.user
          pass: config.api.pass


        @sendRequest options,(error,result)->
          if error?
            callback error
          else
            callback null, result.result.details.id.$t

  startServer: (options,callback)->
    # start container

    # id # container id
    # username

    api_request =
      pathname: '/api/virtual_servers/start'
      query:
        id: options.id

    options =
      req : api_request
      user: options.username
      pass: config.api.defaultPass

    @sendRequest options, (error, result)->
      if error?
        callback error
      else
        callback null, result

  stopServer: (options,callback)->
    # stop container

    # id # container id
    # username

    api_request =
      pathname: '/api/virtual_servers/stop'
      query:
        id: options.id

    options =
      req : api_request
      user: options.username
      pass: config.api.defaultPass

    @sendRequest options, (error, result)->
      if error?
        callback error
      else
        callback null, result

  restartServer: (options,callback)->
    # restart container

    # id # container id
    # username

    api_request =
      pathname: '/api/virtual_servers/restart'
      query:
        id: options.id

    options =
      req : api_request
      user: options.username
      pass: config.api.defaultPass

    @sendRequest options, (error, result)->
      if error?
        callback error
      else
        callback null, result
        
  deleteServer: (options,callback)->
    # delete container

    # id # container id

    api_request =
      pathname: '/api/virtual_servers/delete'
      query:
        id: options.id

    options =
      req : api_request
      user: config.api.user
      pass: config.api.pass

    @sendRequest options, (error, result)->
      if error?
        callback error
      else
        callback null, result



ovz = new OpenVZ

#ovz.fetchUserID username:'aleksey2',(err,res)->
#  if res
#    console.log res
#  else
#    console.log err

#ovz.createUser username:'aleksey8',(err,res)->
#  console.log err,res

ovz.createServer username:'aleksey8',diskspace:10,os_template:'suse-12.1-x86_64',vmtype:'vswap-1g',hostname:'koko10.vm.koding.com',password:'123',expiration_date:'2012.07.30',(err,res)->
  console.log err,res
  ovz.startServer username: 'aleksey8',id:res,(err,res)->
    console.log err,res

#ovz.startServer username:'aleksey8',id:'57',(err,res)->
#ovz.restartServer username:'aleksey8',id:'57',(err,res)->
#ovz.deleteServer id:'57',(err,res)->

#ovz.stopServer username:'aleksey8',id:'57',(err,res)->
#  console.log err, res

#ovz.fetchServers username:'aleksey8',(err,res)->
#  console.log err, res
