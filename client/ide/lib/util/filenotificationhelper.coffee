showError = require 'app/util/showError'
FilePermissionsModal = require '../views/modals/filepermissionsmodal'

module.exports = 

  showReadOnlyModal: ->

    new FilePermissionsModal
      title      : 'Read-only file'
      contentText: 'You can proceed with opening the file but it is opened in read-only mode.'


  showAccessDeniedModal: ->

    new FilePermissionsModal
      title      : 'Access Denied'
      contentText: 'The file can\'t be opened because you don\'t have permission to see its contents.'


  showOperationUnsuccessfulModal: ->

    new FilePermissionsModal
      title      : 'Operation Unsuccessful'
      contentText: 'Please ensure that you have write permission for this file and its folder.'


  showNotificationForError: (err, save = no) ->

    if (err?.message?.indexOf 'permission denied') > -1
      if save
        @showOperationUnsuccessfulModal()
      else
        @showAccessDeniedModal()
      return yes
