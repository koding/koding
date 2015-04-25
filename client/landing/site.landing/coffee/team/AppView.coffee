CustomLinkView = require './../core/customlinkview'

module.exports = class TeamView extends KDView

  viewAppended: ->

    @updatePartial "<h1>#{KD.config.group.title}'s team on Koding.</h1>"

    @addSubView new KDInputView
      placeholder : 'username'

    @addSubView new KDInputView
      type        : 'password'
      placeholder : 'password'
