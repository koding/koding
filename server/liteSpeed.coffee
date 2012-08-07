
fs      = require "fs"
_       = require 'underscore'
log4js  = require 'log4js'
log     = log4js.getLogger '[Litespeed]'
util    = require "util"
{exec}  = require 'child_process'
path    = require "path"
{EventEmitter}   = require 'events'


stringParser =
    
    getStringBetweenTwoStringsThatContainsAString : (options)->
      # to be done. this is necessary to pick things like, foo.kodingen.com between <member> </member>
      #
      # options
      #   string    :
      #   contains  :
      #   str1      :
      #   str2      :
      #   includeStr1And2 : yes/no
      #
      
      
    getStringBetweenTwoStrings : (options)->
      
      #
      # options
      #   string :
      #   str1   :
      #   str2   :
      #   includeStr1And2 : yes/no
      #
      
      {string,str1,str2,includeStr1And2} = options
      
      startsAt = string.indexOf str1
      endsAt   = string.indexOf str2,startsAt      
      result   = string.slice startsAt,endsAt
      if includeStr1And2 is no
        result = result.slice str1.length
      else
        result += str2
      
      return result
    
    getStringOutsideOfTwoStrings : (options) ->

      #
      # options
      #   string :
      #   str1   :
      #   str2   :
      #   includeStr1And2 : yes/no
      #
      
      {string,str1,str2,includeStr1And2} = options      

      firstStringEndsAt     = string.indexOf str1
      secondStringStartsAt  = string.indexOf str2
      
      firstString   = string.slice 0,firstStringEndsAt
      secondString  = string.slice secondStringStartsAt
      
      if includeStr1And2 is no
        res =
          firstString   : firstString
          secondString  : secondString.slice str2.length
      else
        res =
          firstString   : firstString+str1
          secondString  : secondString
          
      return res

class Litespeed extends EventEmitter


  constructor:(cfg)->
    @lsConfig =
      firstPart : ""
      midPart   : ""
      lastPart  : ""
    @config = cfg
    @parsingIsInProgress = yes
    @liteSpeedRestartIsInProgress = no
    @liteSpeedRestartRequestCounter = 0
    
    @throttledWriteConfig      = _.throttle @writeConfig,@config.minRestartInterval
    @throttledRestartLitespeed = _.throttle @restartLitespeed,@config.minRestartInterval
    @parseConfig()
    @watchConfigFileChanges()
    @reparse = yes

  watchConfigFileChanges:()->
    fs.watchFile @config.configFilePath, (curr, prev) =>
      log.debug "reparse flag is "+@reparse
      if @reparse is yes
        # this value is set by writeConfig we don't need to reparse when it's our process that changed it.
        @parseConfig()
        log.info "ls config is changed by another program, re-parsing now, you can't add vhosts until this is done."
      else                        
        # reset the dont reparse value.
        @reparse = yes

  addVhost : (options,callback)->

    #
    # adding virtual host to the litespeed xml config
    #

    #
    # options =
    #   username        : String #username of the unix user
    #   virtualHostname : String #domain name <username>.koding.com or <something else>.koding.com
    #   aliases           : String #comma separated aliases for the domain.
    #   templateName    : String # vhost template name, like PHPsuExec,EasyRailsWithSuEXEC etc
    #   restart         : Boolean# yes/no  optional, if u like litespeed to restart after adding sub/domain. default is no.
    #
    # return value : xml config for vhost
    log.debug options.restart
    if @parsingIsInProgress is yes
      err = "Parsing is in progrees, can't add vhost now."
      log.error err
      callback err
      return

    {username,virtualHostname,aliases,templateName,restart} = options

    templateName ?= "PHP_SuEXEC"
    aliases ?= ""

    vhostpath = path.join @config.baseDir,username,"Sites",virtualHostname
    log.debug "adding #{virtualHostname} for #{username} with path #{vhostpath}"

    if virtualHostname?
      XmlForVhost  = "<member><vhName>#{virtualHostname}</vhName><vhAliases>#{aliases}</vhAliases><vhRoot>#{vhostpath}</vhRoot></member>\n"
      if @lsConfig.midPart[templateName]?
        @lsConfig.midPart[templateName] += XmlForVhost
        log.debug "Vhost config for #{virtualHostname} is appended to @lsConfig.midPart.#{templateName}, call writeConfig to turn this into xml and save it, and restart lsws."
        callback null,XmlForVhost
      else
        log.error "Templatename: #{templateName} does not exist, can't add #{virtualHostname}"
        # log.debug @lsConfig.midPart
        callback "[ERROR] you must provide virtualHostname"

    else
      callback "[ERROR] you must provide virtualHostname"

  checkVhost:(options,callback)->

    #
    # options =
    #   domainName : String
    #

    for template of @lsConfig.midPart
      log.debug "checking #{options.virtualHostname} in \"#{template}\" template"
      searchRes =  @lsConfig.midPart[template].search options.virtualHostname
      count = 0
      if searchRes > 0
        count +=1
        break

    if count is 0
      callback "cant find vhost #{options.virtualHostname}"
    else
      log.debug "[OK] #{options.virtualHostname} present in \"#{template}\" template"
    #  callback null,"#{options.virtualHostname} present in \"#{template}\" template"


  
  parseConfig : (callback)->

    #
    # this method will parse litespeed config and return 3 parts of them...
    #
    
    @parsingIsInProgress = yes
    
    {getStringOutsideOfTwoStrings, getStringBetweenTwoStrings} = stringParser
    
    getVhostTemplatesObject = (vhTemplateListString)->
      vhostTemplatesObject = {}
      vhTemplates = vhTemplateListString.split "</vhTemplate>"
      for own vhTemplate in vhTemplates
        templateName = getStringBetweenTwoStrings string:vhTemplate,str1:"<name>",str2:"</name>",includeStr1And2:no
        vhostTemplatesObject[templateName] = vhTemplate if templateName isnt ""
      return vhostTemplatesObject
           
    

    log.debug "Parsing #{@config.configFilePath}"
    fs.readFile @config.configFilePath,"ascii",(err,data)=>
      throw err if err
      a = {}
      if data is ""
        data = fs.readFileSync @config.lsMasterConfig
        log.error "httpd_config.xml is corrupt."
      unless err        
        vhTemplateListString  = getStringBetweenTwoStrings string:data,str1:"<vhTemplateList>",str2:"</vhTemplateList>",includeStr1And2:no        
        vhostTemplatesObject  = getVhostTemplatesObject vhTemplateListString
        firstAndLastPart      = getStringOutsideOfTwoStrings string:data,str1:"<vhTemplateList>",str2:"</vhTemplateList>",includeStr1And2:yes
        
        @lsConfig.firstPart = firstAndLastPart.firstString                
        @lsConfig.midPart   = vhostTemplatesObject
        @lsConfig.lastPart  = firstAndLastPart.secondString
        log.debug "Parsing #{@config.configFilePath} complete."
        @parsingIsInProgress = no
        @emit "parse complete"

  makeConfigXml:()->
    vhTemplateList = ""    
    for own template,val of @lsConfig.midPart 
      vhTemplateList += val+"</vhTemplate>"
    @lsConfig.firstPart+vhTemplateList+@lsConfig.lastPart

  restartLitespeed:(callback)->

    #
    # gracefully restart web server with zero down time
    #

    log.debug "Restarting Litespeed"
    @liteSpeedRestartRequestCounter = 0
    @liteSpeedRestartIsInProgress = yes

    child = exec "#{@config.controllerPath} restart", (err, stdout, stderr) ->
      if err?
        callback "[ERROR] can't restart litespeed: #{stderr}"
      else
        process.nextTick ()->
          callback null,"[OK] litespeed is restarted"
          @liteSpeedRestartIsInProgress = no

  backupConfigFile : (callback)->

    #
    # this method will crate backup of litespeed config
    #

    fs.readFile @config.configFilePath,@config.encoding,(err,currentConfig)=>
      if err?
        callback  "[ERROR] can't backup litespeed config #{@config.configFilePath}: #{err.message}"
      else
        date = (new Date()).getTime()
        fs.writeFile "#{@config.configFilePath}_#{date}.xml",currentConfig,(err)=>
          if err?
            callback  "[ERROR] can't backup litespeed config #{@config.configFilePath}: #{err.message}"
          else
            callback null,"[OK] litespeed config  #{@config.configFilePath} is backuped to #{@config.configFilePath}_#{date}.xml"

  writeConfig:(options,callback)->

    #
    # this method will write new domain to the litespeed config
    #
    # options =
    #   restart    : Boolean# true/false if u like litespeed to restart after adding sub/domain. default is no.
    #

    {restart} = options if options?.restart?

    newConfig = @makeConfigXml()
    @backupConfigFile (error,result)=>
      if error? then log.error error
      else
        log.debug result
        fs.writeFile @config.configFilePath, newConfig, (err)=>
          if err?
            error = "[ERROR] can't write new litespeed config: #{err.message}"
            log.error error; callback? error
          else
            log.info "[OK] New Litespeed config file is saved to #{@config.configFilePath}"
            @reparse = no
            if restart? and callback? then @restartLitespeed callback
            else callback? null



  removeVhost:(vhost,callback)->
    # not tested
    if vhost.subdomain?
      xml     = "<member><vhName>#{vhost.subdomain}.#{vhost.domain}</vhName><vhAliases>#{vhost.aliases}</vhAliases><vhRoot>/var/www/vhosts/#{vhost.domain}/subdomains/#{vhost.subdomain}</vhRoot></member>\n" 
    else
      xml     = "<member><vhName>#{vhost.domain}</vhName><vhAliases>#{vhost.aliases}</vhAliases><vhRoot>/var/www/vhosts/#{vhost.domain}</vhRoot></member>\n"
    
    @lsConfig.midPart.replace(xml,"")
    
    
    if vhost.restart?
      @throttledWriteConfig restart:true,()->
        callback? null
    else
      callback? null
    
  cleanVhostsFromConfig:()-> @lsConfig.midPart = ""
  


  
  rescueConfig:(callback)->
    fs.readFile @config.lsMasterConfig,(cfgFile)->
      fs.writeFile @config.configFilePath,cfgFile,(err)->
        callback null
        





module.exports = Litespeed

###

#
# USAGE
#

a = new Litespeed configFilePath : "/opt/lsws/conf/httpd_config.xml", controllerPath: "/opt/lsws/bin/lswsctrl"

a.on "parse complete",()->

  vhost =     
    username          : "devrim"
    templateName      : "EasyRailsWithSuEXEC"
    virtualHostname   : "devrim.koding.com"
    aliases           : "boo.com,goo.com"

  a.addVhost vhost,()->
    a.writeConfig restart:yes,(err)->
      log.debug "done"




