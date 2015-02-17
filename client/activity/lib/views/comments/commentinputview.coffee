kd = require 'kd'
ActivityInputView = require '../activityinputview'


module.exports = class CommentInputView extends ActivityInputView

  constructor: (options = {}, data) ->

    options.cssClass            = kd.utils.curry 'comment-input-view', options.cssClass
    options.attributes        or= {}
    options.minHeight          ?= 30
    options.attributes.testpath = "CommentInputView"

    super options, data

