FSHelper = require './fs/fshelper'

module.exports =  (fullPath) ->
  return no unless fullPath

  path       = FSHelper.plainPath fullPath
  basename   = FSHelper.getFileNameFromPath fullPath
  parent     = FSHelper.getParentPath path
  machineUid = FSHelper.getUidFromPath fullPath
  isPublic   = FSHelper.isPublicPath fullPath

  return { path, basename, parent, machineUid, isPublic }
