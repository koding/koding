class JHost extends jraphical.Module


  @set
    schema:
      hostname  : String
      port      : String
      name      : String
      desc      : String
      
class JEnvironment extends jraphical.Module
  
  log4js      = require "log4js"
  log         = log4js.getLogger("[JEnvironment]")
    
  @share()

  @set
    sharedMethods: 
      # instance : ['getMountedDisks', 'accessMount', 'run', 'safePath', 'uploadFile', 'searchFile', 'extract', 'makePublic', 'saveToDefaultCodeSnippetFolder']
      instance : ['getMountedDisks', 'accessMount' ]
    schema:
      environmentId : Number
      hosts         : [JHost]
      kites         : Object
  
  defaultConfig:()->
    environment = ""

  discoverKite : ({kiteName,setKite},callback)=>
    {hostname} = kiteConfig.kites.sharedHosting

    if kiteName in ["sharedHosting","terminaljs","fsWatcher"]
      kiteController.query {kiteName,hostname},(err,kiteIds)=>
        # # log.debug "got the kites",{kiteIds,kiteName,hostname,setKite}
        kiteId = kiteIds[0]
        if setKite
          @setKite kiteName,kiteId,callback
        else
          callback null,kiteId
    else
      kiteController.query {kiteName},(err,kiteIds)=>
        kiteId = kiteIds?[0]
        if setKite
          @setKite kiteName,kiteId,callback
        else
          callback null,kiteId

  
  getKiteId:(options,callback)->
    {kiteName,discover,setKite,reset} = options
    # log.debug "-->",options
    kites = @getAt("kites")
    id = if kites
      @getAt("kites")[kiteName]

    if id and not reset
      callback null,id
    else
      if discover
        # # log.debug "discovering the kite"
        @discoverKite {kiteName,setKite: yes},(err,kiteId)->
          if err
            callback { kiteNotPresent : "no kite found by the name #{kiteName}",kiteName}
          else
            callback null,id

      callback { kiteNotPresent : "no kite is attached to the environment by the name : #{kiteName}",kiteName}
      
    
  setKite:(kiteName,id,callback)->
    # log.debug "aaa",{kiteName,id}
    if kiteName and id
      kites = @getAt("kites")
      if kites?[kiteName] is id
        callback null,id
      else
        modifier = $set : {} 
        modifier.$set["kites.#{kiteName}" ] = id
        @update modifier, (err)->
          unless err
            callback null,id
            # log.debug "kite set",kiteName,id
          else
            # log.debug "kite couldn't be set",err
            callback err
        log.info "you're now using #{kiteName} kiteId:#{id}."
      # callback? null,id # THIS IS CALLING BACK TWICE
    else      
      callback? " kiteName:#{kiteName} or kiteId:#{id} is not correct."


  unsetKite : ({kiteId,kiteName},callback)->
    if kiteId
      for own name,id of @getAt("kites")
        if id is kiteId
          # debugger
          modifier = $unset : {}
          modifier.$unset["kites.#{name}"] = 1
          # console.log modifier
          
          @update modifier, (err)=>
            unless err
              callback null,id
              # log.debug "kite unset --chris",@,modifier
            else
              # log.debug "kite can't be unset",err
              callback err
          

    else if kiteName
      for own name,id of @kites      
        kn = name if name is kiteName
        break

      modifier.$unset["kites.#{kn}"] = 1
      @update modifier, (err)->
        unless err
          callback null,id
          # log.debug "kite unset"
        else
          # log.debug "kite can't be unset",err
          callback err
      
      



  
  getMountedDisks: bongo.secure (client, callback)->
    #FIXME: add api call with account and environment
    callback [
      type : "mount"
      path : "/Users/"+client.connection.delegate.profile.nickname
      name : client.connection.delegate.profile.nickname
    ]
  
  accessMount: bongo.secure (client, callback)->
    log 'gimmmmme some kite action'
    
  # run: bongo.secure (client, command, callback)->
  #   account = client.connection.delegate
  #   # log.debug "got cmd:",command
  #   account.tellKite kiteName:"sharedHosting",method:"executeCommand",withArgs:{command}, (error, response) ->
  #     warn "Error: #{error} from command: #{command}" if error
  #     callback error, response
  # 
  #     
  # searchFile: bongo.secure (client, options, callback)->
  #   account = client.connection.delegate
  #   account.tellKite kiteName:"sharedHosting",method:"searchFiles",withArgs:options, (error, response) ->
  #     callback error, response
  #     
  # extract: bongo.secure (client, options, callback)->
  #   account   =     client.connection.delegate
  #   account.tellKite kiteName:"sharedHosting",method:"smartUnarchiver",withArgs:options, (error, response) ->
  #     callback error, response
      
  # makePublic: bongo.secure (client, options, callback)->
  #   account   =     client.connection.delegate
  #   account.tellKite kiteName:"sharedHosting",method:"prepareFileForDownload",withArgs:options, (error, response) ->
  #     callback error, response

  #FIXME::!!!! These are un-secure- sah 12/27/11
  # safePath: bongo.secure (client, {filePath}, callback)->
  #   account   = client.connection.delegate
  #   account.tellKite kiteName:"sharedHosting",method:"returnSafeFileName",withArgs:{filePath}, (error, response) ->
  #     callback error, response
    
  # uploadFile: bongo.secure (client, file, callback)->
  #   account   = client.connection.delegate
  #   {path} = file
  #   account.tellKite kiteName:"sharedHosting",method:"uploadFile",withArgs:file, (error, response) ->
  #     # log 'emulating upload error'
  #     # error = 'wtf'
  #     callback error, response
  
  # saveToDefaultCodeSnippetFolder: bongo.secure (client, title, contents, callback)->
  #   # This custom method is used because FS, command, environment are all a mess and devrim is currently working on refactoring them - 3/15/12 sah
  #   env = @
  #   dirPath = "#{client.connection.delegate.getRootPath()}/CodeSnippets"
  #   env.run client, "mkdir -p #{dirPath}", (error, response)->
  #     if error then callback error
  #     else
  #       env.safePath client, filePath : "#{dirPath}/#{title}", (error, safePath)->
  #         if error then callback error
  #         else
  #           env.uploadFile client, {contents}, (error, url)=>
  #             if error 
  #               callback error 
  #             else 
  #               env.run client, "curl -L #{url}>#{safePath}", (error, response)->
  #                 callback error, safePath
    
