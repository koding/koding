hosting     = require './sharedHostingApi'
fileops     = require './fileOperationApi'
#mountRemote = require './remoteFilesystemsApi'

__resReport = (error,result,callback)->
  if error
    callback? error
  else
    callback? null,result

requireThese = (requiredVars, receivedObject,callback)->
  return callback yes for own key,val of requiredVars when not receivedObject[key]?
  return callback null

sharedHostingKites =

  eventLikeFn : (options,callback)->
    x = 0
    setInterval ->
      callback x++
    ,1000

  createUser : (options,callback)->

    # create OS user with default virtualhost <username>.koding.com

    #
    # options =
    #   username : String # OS username
    #   fullName : String # real user name
    #   password : String # super strong password
    #

    # requireThese ["username","password"]

    hosting.createSystemUser options,(error,result)->
      if error
        callback? "[ERROR] hosting user #{options.username} wasn't created #{error}"
      else
        location = result
        hosting.createVirtualHost options,(error,result)->
          if error
            callback? error
          else
            callback? null,location

  createVirtualHost : (options,callback)->

    # create additional virtual host for user

    #
    # options =
    #   username         : String # OS username
    #   virtualHostname  : String # virtualHostname (without domain name)
    #

    hosting.createVirtualHost options,(error,result)->
      __resReport(error,result,callback)

  checkVirtualHost : (options,callback)->

    # create litespeed config for virtual host if vhost present on FS but not in litespeed

    #
    # options =
    #   username         : String # OS username
    #

    hosting.checkVirtualHost options,(error,result)->
      __resReport(error,result,callback)

  renameVirtualHost : (options,callback)->

    # rename virtual host

    # options =
    #   username           : String  #username of the unix user
    #   oldVirtualHostname : String  #old virtual hostname - vhostname to rename (without .koding.com)
    #   newVirtualHostname : String  #new virual hostname (without .koding.com)

    hosting.renameVirtualHost options,(error,result)->
      __resReport(error,result,callback)


  deleteVirtualHost : (options,callback)->

    # delete virtual host

    #
    # options =
    #   username         : String # OS username
    #   virtualHostname  : String # virtualHostname (without domain name)
    #

    hosting.deleteVirtualHost options,(error,result)->
      __resReport(error,result,callback)

  changeUserPassword : (options,callback)->

    # change OS user's password

    #
    # options =
    #   username    : String # OS username
    #   newPassword : String # new superstrong password
    #

    hosting.changePassword options, (error,result)->
      __resReport(error,result,callback)

  suspendUser : (options,callback)->

    # suspend OS user

    #
    # options =
    #    username   : String # OS username
    #

    hosting.suspendUser options,(error,result)->
      __resReport(error,result,callback)

  unSuspendUser: (options,callback)->

    # unsuspend OS user

    #
    # options =
    #    username   : String # OS username
    #

    hosting.unSuspendUser options,(error,result)->
      __resReport(error,result,callback)

  executeCommand : (options,callback)->

    # execute OS command for <username>

    #
    # options =
    #    username   : String # OS username
    #    command    : String # OS command
    #

    hosting.executeCommand options,(error,result)->
      __resReport(error,result,callback)

  fileTree : (options,callback)->

    # list files in the user's directory


    #
    # options =
    #   username         : String  #username of the unix user
    #   directory        : String  #directory path - example : "/" or "vhostname.koding.com/cgi-bin"
    #

    fileops.fileTree options, (error,result)->
      __resReport(error,result,callback)


  # **************** Editor operations *********************
  openFile : (options,callback)->

    # copy file to publuic vhost dir

    #
    # options =
    #   username   : String #username of the unix user
    #   pathToFile : String #path to file : example : <username_vhost>.koding.com/httpdocs/index.php
    #
    fileops.openFile options, (error,result)->
      __resReport(error,result,callback)

  uploadFile : (options,callback)->

    fileops.uploadFile  options, (error,result)->
      __resReport(error,result,callback)

  fetchFileFromUrl : (options,callback)->

    fileops.fetchFileFromUrl options, (error,result)->
      __resReport(error,result,callback)

  returnSafeFileName : (options,callback)->
    fileops.returnSafeFileName options, (error,result)->
      __resReport(error,result,callback)


  saveFile : (options,callback)->

    # save file from editor

    #
    # options =
    #   username   : String #username of the unix user
    #   pathToFile : String #path to file : example : Sites/<username_vhost>.koding.com/httpdocs/index.php
    #   content    : String #data which should be written to file <pathToFile>

    fileops.saveFile  options, (error,result)->
      __resReport(error,result,callback)

  makeDir : (options,callback)->

    # create directory

    #
    # options =
    #   username   : String #username of the unix user
    #   pathToDir  : String #path to new dir : example : Sites/<username_vhost>.koding.com/httpdocs/<new_dir>
    #

    fileops.makeDir  options, (error,result)->
      __resReport(error,result,callback)

  smartUnarchiver : (options,callback)->

    # uncompress any archive type (supported now : zip, tar.gz, tar.bz2, gz, bz2 )

    #
    # options =
    #   username      : String #username of the unix user
    #   pathToArchive : String #full path to archive (with /Users/<username>)
    #   dest          : String #destination full path for uncopressed file (with /Users/<username>)
    #

    fileops.uncompress options,(error,result)->
      __resReport(error,result,callback)

  prepareFileForDownload : (options,callback)->


    # put user's file to the public dir for downloads


    # options =
    #   username   : String  #username of the unix user
    #   pathToFile : Array # array with one or more paths to files (full path with /Users/<usernaeme>
    #   archiver   : zip, gz (for one file), tar.gz (for dir),7zip


    fileops.prepareFileForDownload options,(error,result)->
      __resReport(error,result,callback)



  prepareImgForDownload : (options,callback)->

    # put user's image to the public dir
    # each user has context (created in the litespeed):
    # http://<username>.koding.com/kd_public_dir_for_images/
    # which is alias to /opt/lsws/DEFAULT/html/kd_public_dir_for_images

    # options =
    #   username   : String  #username of the unix user
    #   pathToImage : String #full path to image (with /Users/<usernaeme>)

    # return
    #   String #  public image url http://<vhost>.<koding_domain>/kd_public_dir_for_images/<username>/<ramdom_has>/<image.file>



    fileops.prepareImgForDownload options,(error,result)->
      __resReport(error,result,callback)



  searchFiles : (options,callback)->

    # search for file in dir recursive


    # options =
    #    username      : String # OS username
    #    pathToDir     : String # path to dir where to search without /Users/<username>
    #    regexp        : A regular expression
    #    caseSensitive : boolean (true - case sensitive, false - case insensitive)


    hosting.searchForFiles options,(error,result)->
      __resReport(error,result,callback)

  searchInFiles : (options,callback)->

    # recursive search in files

    #
    # options =
    #    username      : String # OS username
    #    pathToDir     : String # path to dir where to search without /Users/<username>
    #    regexp        : A regular expression
    #    caseSensitive : boolean (true - case sensitive, false - case insensitive)

    hosting.searchInFiles options,(error,result)->
      __resReport(error,result,callback)

# **************** End of Editor operations *********************

#  mountSshFS : (options,callback)->
#
#    # mount remote ssh drive
#
#    #
#    # options =
#    #   username     : String # OS username
#    #   mountPoint   : String # local mount point
#    #   remoteServer : String # remote server address
#    #   remoteUser   : String # remote server user
#    #   remoteDir    : String # directory on the remote server
#    #   remotePass   : String # remote user password
#    #   remotePort   : Number # remote server port (optional) - default 22
#
#    mountRemote.mountSshFS options,(error,result)->
#      __resReport(error,result,callback)

  showProcesses : (options,callback)->

    # show user's OS processes

    #
    # options =
    #   username : username : String #username of the unix user
    #

    hosting.showProcesses options, (error,result)->
      __resReport(error,result,callback)


module.exports = sharedHostingKites


