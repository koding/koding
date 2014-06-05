class CommentDeleteModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title    = 'Delete comment'
    options.content  = '<div class="modalformline">Are you sure you want to delete this comment?</div>'
    options.height   = 'auto'
    options.overlay ?= yes
    options.buttons  =
      Delete         :
        style        : 'modal-clean-red'
        loader       :
          color      : '#e94b35'
        callback     : @bound 'submit'
      Cancel         :
        style        : 'modal-cancel'
        callback     : @bound 'destroy'

    super options, data


  submit: ->

    {id} = @getData()

    KD.singleton('appManager').tell 'Activity', 'delete', {id}, (err) =>

      @buttons.Delete.hideLoader()
      @destroy()

      if err
        return new KDNotificationView
          type     : 'mini'
          cssClass : 'error editor'
          title    : 'Error, please try again later!'

      @emit "Deleted"
