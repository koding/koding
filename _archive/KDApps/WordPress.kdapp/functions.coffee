#
# App Globals
#

kc         = KD.getSingleton "kiteController"
fc         = KD.getSingleton "finderController"
tc         = fc.treeController
{nickname} = KD.whoami().profile
appStorage = new AppStorage "wp-installer", "1.0"

#
# App Functions
#

parseOutput = (res, err = no)->
  res = "<br><cite style='color:red'>[ERROR] #{res}</cite><br>" if err
  {output} = split
  output.setPartial res
  output.utils.wait 100, ->
    output.scrollTo
      top      : output.getScrollHeight()
      duration : 100

prepareDb = (callback)->

  dbUser = dbName = __utils.generatePassword 15-nickname.length, yes
  dbPass = __utils.generatePassword 40, no

  parseOutput "<br>creating a database....<br>"
  kc.run
    kiteName  : "databases"
    toDo      : "createMysqlDatabase"
    withArgs  : {dbName, dbUser, dbPass}
  , (err, response)=>
    if err
      parseOutput err.message, yes
      callback? err
    else
      parseOutput """
        <br>database created:<br>
        Database User: #{response.dbUser}<br>
        Database Name: #{response.dbName}<br>
        Database Host: #{response.dbHost}<br>
        Database Pass: #{response.dbPass}<br>
        <br>
        """
      callback null, response

checkPath = (formData, callback)->

  {path, domain} = formData

  kc.run
    withArgs  :
      command : "stat /home/#{nickname}/Sites/#{domain}/website/#{path}"
  , (err, response)=>
    parseOutput "Specified path isn't available, please delete it or select another path!", yes if response
    callback? err, response

installWordpress = (formData, callback)->

  {path, domain, timestamp} = formData

  commands =
    a : "mkdir -vp '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    b : "curl --location 'http://wordpress.org/latest.zip' >'/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"
    # b : "curl --location 'http://sinan.koding.com/planet.zip' >'/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"
    c : "unzip '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip' -d '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    d : "chmod 774 -R '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"
    e : "rm '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}.zip'"
    # f : "mv '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/home/sinan/Sites/sinan.koding.com/website/planet' '/home/#{nickname}/Sites/#{domain}/website/#{path}'"
    f : "mv '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/wordpress' '/home/#{nickname}/Sites/#{domain}/website/#{path}'"
    g : "rm -r '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}'"

  if path is ""
    commands.f = "cp -R /home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/wordpress/* /home/#{nickname}/Sites/#{domain}/website"
    # commands.f = "cp -R '/home/#{nickname}/Sites/#{domain}/website/app.#{timestamp}/home/sinan/Sites/sinan.koding.com/website/planet/*' '/home/#{nickname}/Sites/#{domain}/website'"


  parseOutput commands.a
  kc.run withArgs  : command : commands.a , (err, res)->
    if err then parseOutput err, yes
    else
      parseOutput res
      parseOutput "<br>$> " + commands.b + "<br>"
      kc.run withArgs  : command : commands.b , (err, res)->
        if err then parseOutput err, yes
        else
          parseOutput res
          parseOutput "<br>$> " + commands.c + "<br>"
          kc.run withArgs  : command : commands.c , (err, res)->
            if err then parseOutput err, yes
            else
              parseOutput res
              parseOutput "<br>$> " + commands.d + "<br>"
              kc.run withArgs  : command : commands.d , (err, res)->
                if err then parseOutput err, yes
                else
                  parseOutput res
                  parseOutput "<br>$> " + commands.e + "<br>"
                  kc.run withArgs  : command : commands.e , (err, res)->
                    if err then parseOutput err, yes
                    else
                      parseOutput res
                      parseOutput "<br>$> " + commands.f + "<br>"
                      kc.run withArgs  : command : commands.f , (err, res)->
                        if err then parseOutput err, yes
                        else
                          parseOutput res
                          parseOutput "<br>#############"
                          parseOutput "<br>Wordpress successfully installed to: /home/#{nickname}/Sites/#{domain}/website/#{path}"
                          parseOutput "<br>#############<br>"
                          callback? formData
                          appStorage.fetchStorage ->
                            blogs = appStorage.getValue("blogs") or []
                            blogs.push formData
                            appStorage.setValue "blogs", blogs, noop
                          parseOutput "<br>$> " + commands.g + "<br>"
                          kc.run withArgs  : command : commands.g , (err, res)->
                            if err then parseOutput err, yes
                            else
                              parseOutput res
                              parseOutput "<br>temp files cleared!"
