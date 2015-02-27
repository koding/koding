showError = require 'app/util/showError'
FilePermissionsModal = require '../views/modals/filepermissionsmodal'

module.exports = class FileNotificationHelper

  @showReadOnlyModal: ->

    new FilePermissionsModal
      title      : 'Read-only file'
      contentText: 'You can proceed with opening the file but it is opened in read-only mode.'


  @showAccessDeniedModal: ->

    new FilePermissionsModal
      title      : 'Access Denied'
      contentText: 'The file can\'t be opened because you don\'t have permission to see its contents.'

    return yes


  @showNotificationForError: (err) ->

    if (err?.message?.indexOf 'permission denied') > -1
      @showAccessDeniedModal()
      return yes