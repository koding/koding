kd                     = require 'kd'
remote                 = require 'app/remote'
actions                = require 'app/flux/environment/actions'
FSHelper               = require 'app/util/fs/fshelper'
showError              = require 'app/util/showError'
actiontypes            = require 'app/flux/environment/actiontypes'
FilePermissionsModal   = require './views/modals/filepermissionsmodal'
BannerNotificationView = require 'app/commonviews/bannernotificationview'


module.exports = helpers =


  showFileReadOnlyNotification: ->

    new FilePermissionsModal
      title      : 'Read-only file'
      contentText: 'This file is read-only. You won\'t be able to save your changes.'


  showFileAccessDeniedError: ->

    new FilePermissionsModal
      title      : 'Access Denied'
      contentText: 'The file can\'t be opened because you don\'t have permission to see its contents.'


  showFileOperationUnsuccessfulError: ->

    new FilePermissionsModal
      title      : 'Operation Unsuccessful'
      contentText: 'Please ensure that you have write permission for this file and its folder.'


  showPermissionErrorOnOpeningFile: (err) ->

    if (err?.message?.indexOf 'permission denied') > -1
      helpers.showFileAccessDeniedError()
      return yes


  showPermissionErrorOnSavingFile: (err) ->

    if (err?.message?.indexOf 'permission denied') > -1
      helpers.showFileOperationUnsuccessfulError()
      return yes


  showNotificationBanner: (options) ->

    options.cssClass    = kd.utils.curry 'ide-warning-view', options.cssClass
    options.click     or= kd.noop
    options.container or= kd.singletons.appManager.frontApp.mainView

    return new BannerNotificationView options
