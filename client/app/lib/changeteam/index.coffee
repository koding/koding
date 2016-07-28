kd = require 'kd'
whoami = require 'app/util/whoami'
KodingListController = require 'app/kodinglist/kodinglistcontroller'
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'
ChangeTeamListItem = require './itemview'

module.exports = class ChangeTeamView extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'change-team-modal', options.cssClass
    options.width    = 480
    options.overlay ?= yes

    super options, data

    account = whoami()

    @addSubView new AvatarStaticView
      cssClass   : 'HomeAppView-Nav--avatar'
      size       : { width: 60, height: 60 }
    , account

    @addSubView new kd.CustomHTMLView
      tagName : 'h1'
      partial : 'Switch to Another Team'

    @addSubView new kd.CustomHTMLView
      tagName : 'p'
      partial : 'Here is the list of your teams. Select to switch.'

    listController = new KodingListController
      itemClass           : ChangeTeamListItem
      fetcherMethod       : (query, options, callback) ->
        account.fetchAllParticipatedGroups options, (err, groups) -> callback err, groups

    @addSubView listController.getView()
