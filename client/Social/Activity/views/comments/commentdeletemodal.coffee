class CommentDeleteModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title    = "Delete comment"
    options.content  = "<div class='modalformline'>Are you sure you want to delete this comment?</div>"
    options.height   = "auto"
    options.overlay ?= yes
    options.buttons  =
      Delete         :
        style        : "modal-clean-red"
        loader       :
          color      : "#ffffff"
          diameter   : 16
        callback     : @bound "submit"
      Cancel         :
        style        : "modal-cancel"
        callback     : @bound "destroy"

    super options, data


  submit: ->

    {id} = @getData()

    KD.singleton("appManager").tell "Activity", "delete", {id}, (err) =>

      @buttons.Delete.hideLoader()
      @destroy()

      return  unless err

      new KDNotificationView
        type     : "mini"
        cssClass : "error editor"
        title    : "Error, please try again later!"
