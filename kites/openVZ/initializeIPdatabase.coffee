mongo   = require 'mongodb'
os      = require 'os'
log4js  = require 'log4js'

log     = log4js.getLogger '[IP database]'


# configuration

config =
  ctNameserver0 : '10.0.80.11' # nameserver for containers
  ctNameserver1 : '10.0.80.12'
  systemdb            :
    mongo             :
      host            : "192.168.0.1"
      user            : "system"
      pass            : "{Fq{Vpcw67GW"
      dbName          : "koding_sys"
      collections     :
        ipDatabase      : "ipdb"

# end of configuration



class IpDatabase

  # initialize IP database for OpenVZ containers
  #
  # pass IP object to ip.intializeIpDB(ipobj)
  # example:
  #
  #  options =
  #     networkid : 1
  #     iptemplate: "192.168.1.0"
  #     firstIP   : "192.168.1.1"
  #     lastIP    : "192.168.1.254"
  #     node      : "#{os.hostname()}"

  constructor: (@config) ->

    @MONGO_HOST = @config.systemdb.mongo.host
    @MONGO_USER = @config.systemdb.mongo.user
    @MONGO_PASS = @config.systemdb.mongo.pass
    @MONGO_DB   = @config.systemdb.mongo.dbName
    @COLLECTION = @config.systemdb.mongo.collections.ipDatabase

    server = new mongo.Server @MONGO_HOST, 27017
    @db     = new mongo.Db @MONGO_DB, server

  intializeIpDB: (options)->

    #
    # options =
    #   networkid : Number # Network ID
    #   iptemplate: "192.168.1.0"
    #   firstIP   : "192.168.1.1"
    #   lastIP    : "192.168.1.254"
    #   node      : "#{os.hostname()}"

    {networkid,iptemplate,firstIP,lastIP,node} = options

    firstIP    = firstIP.split('.')[3]
    lastIP     = lastIP.split('.')[3]
    iptemplate = iptemplate.split('.')

    @db.open (error,client)=>
      if error then log.error error
      else
        @db.authenticate @MONGO_USER, @MONGO_PASS,(error,val)=>
          if error then log.error error
          else
            collection = new mongo.Collection client, @COLLECTION

            while parseInt(firstIP) < parseInt(lastIP)
              iptemplate[3] = firstIP++
              ip =
                networkid : networkid
                ip        : iptemplate.toString().replace(/\,/g, '.')
                node      : node
                isfree    : true

              log.debug ip
              collection.insert ip, (error,objects)->
                if error then log.error "Insert: "+error.message
                else
                  log.debug objects


ipdb = new IpDatabase config

options =
  networkid : 3
  iptemplate : '10.56.116.0'
  firstIP    : '10.56.116.98'
  lastIP     : '10.56.116.110'
  node      : "#{os.hostname()}"

ipdb.intializeIpDB options