mongo    = require 'mongodb'
{exec}   = require 'child_process'
fs       = require 'fs'
log4js   = require 'log4js'
os       = require 'os'

log      = log4js.getLogger '[OpenVZ]'


# configuration

config =
  ctNameserver0 : '10.0.80.11' # nameserver for containers
  ctNameserver1 : '10.0.80.12'
  baseDomain    : '.ct.koding.com'
  tempateDir    : '/vz/template/cache/'
  nodeFQDN      : os.hostname()
  systemdb            :
    mongo             :
      host            : "192.168.0.1"
      user            : "system"
      pass            : "{Fq{Vpcw67GW"
      dbName          : "koding_sys"
      collections     :
        ipDatabase      : "ipdb"

# end of configuration

class OpenVZ

  constructor : (@config) ->

    @MONGO_HOST = @config.systemdb.mongo.host
    @MONGO_USER = @config.systemdb.mongo.user
    @MONGO_PASS = @config.systemdb.mongo.pass
    @MONGO_DB   = @config.systemdb.mongo.dbName
    @COLLECTION = @config.systemdb.mongo.collections.ipDatabase


    server = new mongo.Server @MONGO_HOST, 27017
    @db    = new mongo.Db @MONGO_DB, server

  initializeDB : (callback)->

    @db.open (error,client)=>
      if error
        log.error "[ERROR] can't open database : #{error}"
        callback "[ERROR] can't open database : #{error}"
      else
        @db.authenticate @MONGO_USER, @MONGO_PASS,(error,val)=>
          if error
            log.error "[ERROR] db authentication error : #{error}"
            callback "[ERROR] db authentication error : #{error}"
          else
            log.debug "[OK] DB initalized"
            callback null, collection = new mongo.Collection client, @COLLECTION

  findFreeIP : (callback)->

    #
    # search for free IP
    # find end change "isfree" to "false"
    #
    # return IP


    node = config.nodeFQDN

    @initializeDB (error,collection)->
      if error?
        log.error error
      else
        collection.findAndModify isfree:true ,node:node, [ [ "_id", "asc" ] ],$set:isfree: false , new: false, (err, object) ->
          if err
            log.error "[ERROR] can't find free IP: #{err.message}"
            callback? "[ERROR] can't find free IP: #{err.message}"
          else
            if object?.ip?
              log.debug "[OK] free IP for #{node} is #{object.ip}"
              callback? null,object.ip
            else
              log.error "[ERROR] can't find free IP for node #{node}"
              callback? "[ERROR] can't find free IP for node #{node}"


  markIPasFree : (options,callback)->

    #
    # this method will mark IP as free
    #

    #
    # options =
    #   ipaddr    : String # IP address for container , from createCT method
    #
    {ipaddr} = options
    log.debug "mark #{ipaddr}"

    node = config.nodeFQDN

    @initializeDB (error,collection)->
      if error?
        log.error error
      else
        collection.findAndModify isfree:false ,node:node,ip:ipaddr, [ [ "_id", "asc" ] ],$set:isfree: true , new: true, (err, object) ->
          if err
            log.error "[ERROR] can't find non free IP: #{err.message}"
            callback? "[ERROR] can't find non free IP: #{err.message}"
          else
            if object?.ip?
              log.debug "[OK] non free IP for #{node}  #{object.ip} is now free"
              callback? null,object.ip
            else
              log.error "[ERROR] can't find non free IP #{node}"
              callback? "[ERROR] can't find non free IP #{node}"

  fetchTemplates : (callback)->

    #
    # get available templates
    #

    #
    # result - templates array
    #
    templates = []

    fs.readdir config.tempateDir, (err,result)->
      if err?
        log.error "[ERROR] can't read templates: #{err}"
      else
        log.debug "[OK] found templates : #{result}"
        for template in result
          templates.push template.replace '.tar.gz',''
        callback null,templates

  getCPUpercentage = (options,callback)->

    #
    # check max CPU Mhz available for this server,
    # compare it with requested options.cpulimit,
    # if requested Mhz available on this server,
    # convert to % end return
    #

    # options =
    #   cpulimit : Number # CPU Mhz for container
    #

    {cpulimit} = options

    fs.readFile '/proc/cpuinfo', 'ascii', (err,data)->
      if err then callback "Cant open file #{err}"
      else
        res = data.split('\n')
        for line in res
          if line.match(/cpu MHz/) # res will be something like "cpu MHz: 2400.084"
            availMhz = line.split(':')[1].split('.')[0]  # 2400
            break
        if cpulimit >= availMhz
          callback "[ERROR] max #{availMhz} on this server"
        else
          percentage = cpulimit*100/availMhz+'' # +'' converting num to string
          callback null,percentage.split('.')[0]



  createCT : (options,callback)->

    #
    # This method will create OpenVZ container
    # return container ID if  successfully created
    #

    #
    # options =
    #   name      : String # name of the container - first part of the domain name
    #   template  : String # template name. one from available on the server
    #   node      : String # FQDN of hardware node

    {name,template,node} = options

    log.debug "/usr/sbin/vzctl create --hostname #{name}  --name #{name}"
    @findFreeIP (error,result)->
      if error then callback? error
      else
        log.info "[OK] Free IP is #{result} -> creating container"
        octets = result.split('.')
        ctparams =
          id  : octets[1..3].toString().replace(/\,/g, '')
          ip  : result

        exec "/usr/sbin/vzctl create #{ctparams.id} \
                    --ostemplate #{template} \
                    --hostname #{name}#{config.baseDomain} \
                    --name #{name}",(err,stdout,stderr)->
          if err? then callback "[ERROR] cant create container : #{stderr}"
          else
            log.info "[OK] contaner with name #{name} , ID #{ctparams.id} and IP #{ctparams.ip} was created"
            callback null, ctparams

  haltCT : (options,callback)->

    #
    # shutdown container
    #

    #
    # options =
    #   ctID   : Number # container ID
    #   fast   : Boolean # fast makes use reboot(2) syscall which is faster but
    #                    # can lead to unclean container shutdown, so this param should be used for the destruction of the container
    #

    {ctID,fast} = options

    haltCmd = "/usr/sbin/vzctl stop #{ctID}"
    haltCmd = "/usr/sbin/vzctl stop #{ctID} --fast" if fast
    exec haltCmd, (err,stdout,stderr)->
      if err?
        log.error "[ERROR] can't stop container with ID #{ctID}"
        callback  "[ERROR] can't stop container with ID #{ctID}"
      else
        log.info "[OK] container with ID #{ctID} has been stopped"
        callback null, "[OK] container with ID #{ctID} has been stopped"

  destroyCT : (options,callback)->

    #
    # destroy container (should be stopped)
    #

    #
    # options =
    #   ctID   : Number # container ID
    #   ipaddr : String # IP address for container , from createCT method
    #   fast   : Boolean # fast makes use reboot(2) syscall which is faster but
    #                    # can lead to unclean container shutdown, so this param should be used for the destruction of the container

    {ctID,ipaddr} = options

    exec "/usr/sbin/vzctl destroy #{ctID}" ,(err,stdout,stderr)=>
      if err?
        log.error "[ERROR] can't destroy container #{ctID}: #{stderr}"
        callback "[ERROR] can't destroy container #{ctID}: #{stderr}"
      else
        log.info "[OK] container #{ctID} was destroyed"
        @markIPasFree options,(error,result)->
          if error?
            log.error error
          else
            callback null, "[OK] container #{ctID} with IP #{result} was destroyed"

  setCTparams : (options,callback)->

    #
    # this method will set initial params for container
    #

    #
    # options =
    #   ctID      : Number # container ID, from createCT method
    #   ipaddr    : String # IP address for container , from createCT method
    #   password  : String # root password
    #   ram       : Number # RAM for container in MB
    #   swap      : Number # Swap in MB (512 mb is good in most cases)
    #   cpulimit  : Number # Max Mhz available for container
    #   cpus      : Number # sets number of CPUs available in the container
    #   diskspace : Number # disk quota limits in GB
    #

    log.debug "setting params for container: "
    log.debug options
    {ctID,ipaddr,password,ram,swap,cpulimit,cpus,diskspace} = options

    getCPUpercentage options, (err,percentage)=>
      if err then callback "[ERROR] #{err}"
      else
        log.debug "starting setup params with cpulimit #{percentage}"
        exec "/usr/sbin/vzctl set #{ctID} --ipadd #{ipaddr}
                                          --nameserver #{config.ctNameserver0} --nameserver #{config.ctNameserver1}
                                          --userpasswd root:'#{password}'
                                          --physpages #{ram}m
                                          --swappages #{swap}m
                                          --cpulimit #{percentage}
                                          --cpus #{cpus}
                                          --diskspace #{diskspace}G --save",(err,stdout,stderr)=>
          if err?
            log.error "[ERROR] unable to set CT params: #{stderr} -> destroying container"
            # we must destroy unconfigured container!
            @destroyCT options, (err,result)->
              if err?
                callback err
              else
                log.info result
                callback "[ERROR] can't create container"
          else
            callback null,"[OK] all CT params for #{ctID} configured"

  bootCT : (options,callback)->

    #
    # this method will boot installed and configurad container
    #

    # these params will be returned
    # options =
    #   ctID   : Number # container ID, from createCT method
    #   ipaddr : String # IP address for container , from createCT method

    {ctID,ipaddr} = options

    exec "/usr/sbin/vzctl start #{ctID}",(err,stdout,stderr)=>
      if err?
        log.error "[ERROR] can't start container with ID #{ctID}: #{stderr}"
        @destroyCT options, (err,result)->
          if err?
            callback err
          else
            log.info result
            callback "[ERROR] can't create container"
      else
        log.info "[OK] container with ID #{ctID} has been started"
        containerInfo =
          ctID   : ctID
          ipaddr : ipaddr
        callback? null,containerInfo


  fetchCTprocesses : (options,callback)->

    #
    # fetch running processes inside container
    #

    #
    # options =
    #   ctID      : Number # container ID, from createCT method
    #
    #

    {ctID} = options

    procarray = new Array()

    fetchproc = exec "vzctl exec2 105 \"ps -A h -o size -o  '||%p||%C||%a' |grep -v '||ps'\"",(err,stdout,stderr)->
      if err?
        log.error "[ERROR] can't retrieve processes for container ID: #{ctID}: #{stderr}"
        callback? "[ERROR] can't retrieve processes for container ID: #{ctID}: #{stderr}"
      else
        for proc in stdout.split('\n')
          if proc
            process = proc.split('||')
            procarray.push procinfo =
              memory  : process[0]
              pid     : process[1]
              cpu     : process[2]
              command : process[3]
        log.debug "[OK] container's #{ctID} processes : #{procarray}"
        callback? null,procarray

  modifyCT : (options,callback)->

    #
    # this method will modify main container params
    #

    #
    # can be any of the parameters or all at once
    #
    # options =
    #   ctID      : Number # container ID, from createCT method
    #   ipaddr    : String # IP address for container , from createCT method
    #   password  : String # root password
    #   ram       : Number # RAM for container in MB
    #   swap      : Number # Swap in MB (512 mb is good in most cases)
    #   cpulimit  : Number # Max Mhz available for container
    #   cpus      : Number # sets number of CPUs available in the container
    #   diskspace : Number # disk quota limits in GB
    #

    {ctID,ipaddr,password,ram,swap,cpulimit,cpus,diskspace} = options

    log.debug "ctID: #{ctID}"

    if cpulimit?
      getCPUpercentage options,(err,percentage)->
        if err then callback "[ERROR] #{err}"
        else
          # replacing MHz to percentage
          options['cpulimit'] = percentage

    # add "m" (Mbytes) to physpages for OpenVZ command
    if options.ram?
      options['physpages'] = ram+'m'
      delete options['ram']
    # add "m" (Mbytes) to swappages for OpenVZ command
    if options.swap?
      options['swappages'] = swap+'m'
      delete options['swap']
    if options.password?
      options['userpasswd'] = password
      delete options['password']
    # add "G" (Gbytes) to diskspace for OpenVZ command
    if options.diskspace?
      options['diskspace'] = options.diskspace+'G'

    # generate command from limits hash
    log.debug options

    vzctlParams = []
    vzctlParams.push "--#{key} \'#{options[key]}\'" for key of options when key isnt "ctID"

    vzctlParams = vzctlParams.toString().replace(/,/g,' ')
    log.debug "vzctlParams: #{vzctlParams}"
    cmd = "/usr/sbin/vzctl set #{ctID} #{vzctlParams}  --save"
    log.debug "executing: #{cmd}"
    vzctl = exec cmd,(err,stdout,stderr)->
      if err?
        log.error "[ERROR] unable to modify container limits with \"#{cmd}\" for #{ctID}: #{stderr}"
        callback? "[ERROR] unable to modify container limits with \"#{cmd}\" for #{ctID}: #{stderr}"
      else
        log.info "[OK] limits for #{ctID} has been changed with \"#{cmd}\""
        callback? null,"[OK] limits for #{ctID} has been changed with \"#{cmd}\""




ovz = new OpenVZ config

module.exports = ovz



