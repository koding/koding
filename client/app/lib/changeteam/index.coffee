kd = require 'kd'
whoami = require 'app/util/whoami'
ChangeTeamController = require './controller'
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'

module.exports = class ChangeTeamView extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass       = kd.utils.curry 'change-team-modal', options.cssClass
    options.width          = 480
    options.overlay       ?= yes
    options.overlayOptions = { cssClass : 'change-team-modal-overlay' }

    super options, data

    @addSubView new AvatarStaticView
      cssClass   : 'HomeAppView-Nav--avatar'
      size       : { width: 60, height: 60 }
    , whoami()

    @addSubView new kd.CustomHTMLView
      tagName : 'h1'
      partial : 'Switch to Another Team'

    @addSubView new kd.CustomHTMLView
      tagName : 'p'
      partial : 'Here is the list of your teams. Select to switch.'

    controller = new ChangeTeamController()
    @addSubView list = controller.getView()
    controller.on 'AllItemsAddedToList', ->
      # delay is needed to let custom scroll view set their css classes on the list
      kd.utils.defer -> list.setClass 'loaded'
