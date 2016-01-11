getAppIcon = require '../util/getAppIcon'
kd = require 'kd'
KDListItemView = kd.ListItemView
AppLinkView = require './linkviews/applinkview'
JView = require '../jview'


module.exports = class ModalAppsListItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options,data)->
    options.cssClass = 'topic-item'

    super options, data

    @titleLink = new AppLinkView {expandable:no}, data
    @titleLink.on "click", =>
      @getDelegate().emit "CloseTopicsModal"

    @img = getAppIcon @getData(), 'modal-app-icon'

  pistachio:->
    """
    <div class="app-title">
      {{> @img }}
      {{> @titleLink }}
    </div>
    <div class="stats">
      <p class="installs">
        <span class="icon"></span>{{#(counts.installed) or 0}} Installs
      </p>
      <p class="fers">
        <span class="icon"></span>{{#(counts.followers) or 0}} Followers
      </p>
    </div>
    """
