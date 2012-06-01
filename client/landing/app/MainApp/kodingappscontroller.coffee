class KodingAppsController extends KDController

  @apps = {}

  constructor:->

    super

  fetchApps:(callback)->
    
    path = "/Users/#{KD.whoami().profile.nickname}/Applications"
    
    @getSingleton("kiteController").run
      withArgs  :
        command : "ls #{path} -lpva"
    , (err, response)=>
      if err 
        warn err
      else
        files = FSHelper.parseLsOutput [path], response
        apps  = []
        stack = []
        for file in files
          if /\.kdapp$/.test file.name
            apps.push file
        
        apps.forEach (app)->
          manifest = if app.type is "folder" then FSHelper.createFileFromPath "#{app.path}/.manifest" else app
          stack.push (cb)->
            manifest.fetchContents cb
        
        async.parallel stack, (err, results)=>
          if err then warn err else
            results.forEach (app)->
              app = JSON.parse app
              KodingAppsController.apps["#{app.name}-#{app.version}"] = app
            log KodingAppsController.apps
            callback? KodingAppsController.apps
