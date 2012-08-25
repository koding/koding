{Model} = require 'bongo'
jraphical = require 'jraphical'

class JGitBranch extends jraphical.Module
  @setSchema
    repoPath : String
    branch : String
    
class JApplication extends jraphical.Module
  {exec} = require 'child_process'
  {secure} = require 'bongo'
  
  @share()

  @set
    sharedMethods :
      static      : ['some']
      instance    : ['initNewLocalAppDirectory', 'cloneRemoteAppDirectory', 'initNewAdminAppDirectory', 'on', 'save']
    schema:
      name            : 
        type          : String
        required      : yes
      appSubmoduleRepo: JGitBranch
      clonedRepo      : JGitBranch
      pathToKDVersion : String
    relationships:
      creator       :
        targetType  : Account
        as          : 'creator'
      installer     : 
        targetType  : Account
        as          : 'installer'

  constructor:(data)->
    super data # use super instead of @Uber
  
  _createAdminAppDir:(client, callback)->
    application = @
    
    Path.exists (repoPath = "/shared/kdapplications/#{(application.appSubmoduleRepo.repoPath.replace /.*:\/\//, '')}/#{application.appSubmoduleRepo.branch}"), (exists)->
      if exists then callback null, 'application directory already exists'
      else
        application._newSaveStatus 'Ready to create new application'
  
        # app folder path is /shared/kdapplications/clone url path (for uniqueness)/branch name (again for uniqueness)/app name with /s removed.kdapplication
        appPath = "#{repoPath}/#{application.name.replace /\//g, '_'}.kdapplication"
        
        application._newSaveStatus "Creating application directory (#{appPath})"
        
        fs.createPath appPath, (err)->
          if err then callback null, "creating application directory: #{appPath} failed with error #{err}"
          else callback appPath
  
  _createAccountAppDir:(client, callback)->
    {account} = client.connection
    application = @
    
    Path.makeSafe (account.getRootedPath "KDApplications/#{application.name.replace /\//g, '_'}.kdapplication"), (safePath)->
      application._newSaveStatus 'Creating local application directory'
      
      fs.createPath safePath, (err)->
        if err then callback null, "creating application directory: #{safePath} failed with error #{err}"
        else
          callback safePath
  
  cloneRemoteAppDirectory: secure (client, callback)->
    application = @
    
    application._createAccountAppDir client, (safePath, err)->
      if err? then application._errorCleanup err, callback
      else
        application._newSaveStatus 'Cloning application to local directory'
        exec "git clone --recurse-submodules -b #{application.clonedRepo.branch} #{application.clonedRepo.repoPath} #{safePath}", (err, stdout, stderr)->
          if err then application._errorCleanup "application clone failed with error #{err}", callback
          else
            application.addCreator client.connection.account, ->
            # FIXME: after account migration to bongo, relationship should be with account as source, application as installed, I believe
            application.addInstaller client.connection.account, ->
              callback()
  
  initNewAdminAppDirectory: secure (client, callback)->
    application = @
    
    application._createAdminAppDir client, (appPath, err)->
      if err? then application._errorCleanup err, callback
      else
        application.pathToKDVersion = appPath

        application._newSaveStatus 'Initializing application repository'
        exec "git init #{appPath}", (err, stdout, stderr)->
          if err then application._errorCleanup "git init failed with error: #{err}", callback
          else
            application._newSaveStatus 'Cloning remote repository'
            #this line prevents Fatal: Cannot force update the current branch. errors
            branchSwitch = if (branch = application.appSubmoduleRepo.branch) isnt 'master' then " -b #{application.appSubmoduleRepo.branch}" else ''
            exec "cd #{appPath} && git submodule add#{branchSwitch} #{application.appSubmoduleRepo.repoPath}", (err, stdout, stderr)->
              if err then application._errorCleanup "git submodule failed with error #{err}", callback
              else
                exec "cd #{appPath} && touch config.js", (err, stdout, stderr)->
                  if err then application._errorCleanup "Creating config.js failed with error #{err}", callback
                  else
                    application._newSaveStatus 'Committing new application'
                    exec "cd #{appPath} && git add . && git commit -a -m 'Application #{application.name} first commit'", (err, stdout, stderr)->
                      if err then application._errorCleanup "Committing app failed with error #{err}", callback
                      else
                        # github stuff
                        application.addCreator client.connection.account, ->
                          callback()
    
  initNewLocalAppDirectory: secure (client, callback)->
    application = @
    
    application._createAccountAppDir client, (safePath, err)->
      if err? then application._errorCleanup err, callback
      else
        application._newSaveStatus 'Initializing application repository'
        exec "git init #{safePath}", (err, stdout, stderr)->
          if err then application._errorCleanup "git init failed with error: #{err}", callback
          else
            application._newSaveStatus 'Cloning remote repository'
            #this line prevents Fatal: Cannot force update the current branch. errors
            branchSwitch = if (branch = application.appSubmoduleRepo.branch) isnt 'master' then " -b #{application.appSubmoduleRepo.branch}" else ''
            exec "cd #{safePath} && git submodule add#{branchSwitch} #{application.appSubmoduleRepo.repoPath}", (err, stdout, stderr)->
              if err then application._errorCleanup "git submodule failed with error #{err}", callback
              else
                exec "cd #{safePath} && touch config.js", (err, stdout, stderr)->
                  if err then application._errorCleanup "Creating config.js failed with error #{err}", callback
                  else
                    application._newSaveStatus 'Committing new application'
                    exec "cd #{safePath} && git add . && git commit -a -m 'Application #{application.name} first commit'", (err, stdout, stderr)->
                      if err then application._errorCleanup "Committing app failed with error #{err}", callback
                      else
                        application.addCreator client.connection.account, ->
                        # FIXME: after account migration to bongo, relationship should be with account as source, application as installed, I believe
                        application.addInstaller client.connection.account, ->
                          callback()
    
  _newSaveStatus:(status)=>
    @emit 'newSaveStatus', {status}

  _errorCleanup:(message, callback)=>
    callback message