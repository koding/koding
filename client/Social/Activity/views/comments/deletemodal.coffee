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

    { id } = @getData()

    # Emit this event so that
    # listeners do things without waiting
    # server response.
    @emit "DeleteClicked"
    @buttons.Delete.hideLoader()
    @hide()

    KD.singleton('appManager').tell 'Activity', 'delete', {id}, (err) =>

      if err
        return new KDNotificationView
          type     : 'mini'
          cssClass : 'error editor'
          title    : 'Error, please try again later!'

        # with the emit of this event
        # we are giving a way to recover
        # if something goes wrong.
        @emit "DeleteError"
        @show()

      # and finally emit this event so that
      # it is confirmed that it is deleted.
      @emit "DeleteConfirmed"
      @destroy()


  hide: ->
    @overlay?.hide()
    super


  show: ->
    @overlay?.show()
    super
