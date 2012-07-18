#mountRemote = require './remoteFilesystemsApi'




__resReport = (error,result,callback)->
  if error
    callback? error
  else
    callback? null,result


sharedHostingKites =

createUser : (options,callback)->

  # create OS user with default virtualhost <username>.koding.com

  #
  # options =
  #   username : String # OS username
  #   fullName : String # real user name
  #   password : String # super strong password
  #

  hosting.createSystemUser options,(error,result)->