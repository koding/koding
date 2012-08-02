log4js  = require 'log4js'
log     = log4js.addAppender log4js.fileAppender("/var/log/nginxApi.log"), "[NginX]"
log     = log4js.getLogger('[NginX]')

fs      = require 'fs'
{exec}  = require 'child_process'
os      = require 'os'


class Nginx

  constructor : (@upstreamMapFile) ->


  reloadServer : (callback)->

    child = exec "/usr/sbin/nginx -t",(err,stdout,stderr)->
      if err?
        log.error "[ERROR] config test filed: #{stderr}"
        callback? "[ERROR] config test filed: #{stderr}"
      else
        log.debug "[OK] config test success"
        child = exec "/usr/bin/kill -HUP $(cat /var/run/nginx.pid)",(err,stdout,stderr)->
          if err?
            log.error "[ERROR] config test filed: #{stderr}"
            callback? "[ERROR] config test filed: #{stderr}"
          else
            log.info "[OK] nginx has been reloaded"
            callback? null,"[OK] nginx has been reloaded"


  checkMapRecord : (options,callback)->

    #
    # check for map record, if recod exists we should not add the same - nginx will be down..
    #

    #
    # options =
    #   backendSubdomain  : String # Koding subdomain <username>.koding.com (<subdomain>.koding.com) or user defined domain (example.com)
    #
    {backendSubdomain} = options

    re = new RegExp "\^#{backendSubdomain}"

    fs.readFile @upstreamMapFile,'utf8',(err,data)=>
      if err?
        log.error "[ERROR] can't read #{crontabFile} : #{err}"
        callback? "[ERROR] can't read #{crontabFile} : #{err}"
      else
        for mapRecord in data.split('\n')
          if re.test mapRecord
            mapExists = "[ERROR] record for #{backendSubdomain} already exists in the #{@upstreamMapFile}"
            break
        if mapExists?
          log.error mapExists
          callback mapExists
        else
          callback null

  addMapRecord : (options,callback)->

    #
    # add record to nginx map file
    #

    #
    # options =
    #   backendSubdomain  : String # Koding subdomain <username>.koding.com (<subdomain>.koding.com) or user defined domain (example.com)
    #   backendServerAddr : String # backend server address (FQDN - cl0.dev.srv.kodingen.com ... cl100.dev.srv.koding.com)
    #

    {backendSubdomain,backendServerAddr} = options

    string = "#{backendSubdomain} #{backendServerAddr};\n"
    log.debug "adding #{string} to #{@upstreamMapFile}"

    @checkMapRecord options,(error)=>
      if error?
        callback? error
      else
        fs.open @upstreamMapFile,'a+',0600,(err,fd)=>
          if err?
            log.error "[ERROR] can't open crontab file #{@upstreamMapFile} : #{err}"
            callback? "[ERROR] can't open crontab file #{@upstreamMapFile} : #{err}"
          else
            fs.write fd,string,null,'utf8',(err)=>
              if err?
                log.error "[ERROR] can't write data to #{@upstreamMapFile} : #{err}"
                callback? "[ERROR] can't write cronjob to #{@upstreamMapFile} : #{err}"
              else
                @reloadServer (error,result)=>
                  if not error?
                    log.info "[OK] config  #{@upstreamMapFile} has been changed, added \"#{string}\""
                    callback? null, "[OK] config  #{@upstreamMapFile} has been changed, added \"#{string}\""

  removeMapRecord : (options,callback)->

    #
    # remove recored from nginx map file
    #

    #
    # options =
    #   backendSubdomain : String # Koding subdomain <username>.koding.com (<subdomain>.koding.com) or user defined domain (example.com)
    #

    {backendSubdomain} = options

    re = new RegExp "\^#{backendSubdomain}"

    fs.readFile @upstreamMapFile,'utf8',(err,data)=>
      if err?
        log.error "[ERROR] can't read config file: #{err}"
        callback? "[ERROR] can't read config file: #{err}"
      else
        newData = []
        for mapRecord in data.split('\n')
          mapRecord = mapRecord+'\n'
          if re.test mapRecord
            isDisabled = true
            newData.push mapRecord.replace re, "##{backendSubdomain}"
          else
            newData.push mapRecord
        if isDisabled
          fs.open @upstreamMapFile,'w+',(err,fd)=>
            if err?
              log.error "[ERROR] can't open file for writing: #{err}"
              callback? "[ERROR] can't open file for writing: #{err}"
            else
              for record in newData
                try
                  fs.writeSync fd,record,null
                catch err
                  log.error "[ERROR] can't write file: #{err}"
                  callback? "[ERROR] can't write file: #{err}"

              fs.close fd,()=>
                @reloadServer (error,result)->
                  if not error?
                    log.info "[OK] domain #{backendSubdomain} has been disabled"
                    callback? "[OK] domain #{backendSubdomain} has been disabled"
        else # nothing was disabled
          log.error "[ERROR] domain #{backendSubdomain} not found or already disabled"
          callback? "[ERROR] domain #{backendSubdomain} not found or already disabled"

nginx = new Nginx '/etc/nginx/conf.d/hosting_upstream_map'

module.exports = nginx

