CustomLinkView = require './../core/customlinkview'

module.exports = class TeamLandingView extends KDView

  viewAppended: ->

    @updatePartial "<h1>landed to group #{KD.config.groupName}</h1>"

    @addSubView new KDInputView
      placeholder : 'username'

    @addSubView new KDInputView
      type        : 'password'
      placeholder : 'password'
