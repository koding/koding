class CommentInputView extends ActivityInputView

  constructor: (options = {}, data) ->

    options.cssClass            = KD.utils.curry 'comment-input-view', options.cssClass
    options.attributes        or= {}
    options.minHeight          ?= 30
    options.attributes.testpath = "CommentInputView"

    super options, data