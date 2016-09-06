ActivityInputView = require '../activityinputview'


module.exports = class ReplyInputView extends ActivityInputView

  constructor : (options = {}, data) ->

    options.showButton = no

    super options, data
