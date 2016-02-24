kd                     = require 'kd'
JView                  = require 'app/jview'
AvatarView             = require 'app/commonviews/avatarviews/avatarview'


module.exports = class ResourceListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type   or= 'member'
    options.cssClass = kd.utils.curry "resource-item clearfix", options.cssClass

    super options, data

    @detailsToggle = new kd.CustomHTMLView
      cssClass : 'role'
      partial  : "Details <span class='settings-icon'></span>"
      click    : @getDelegate().lazyBound 'toggleDetails', this

    resource = @getData()
    delegate = @getDelegate()

    @details = new kd.CustomHTMLView
      cssClass : 'hidden'

    @details.addSubView new kd.View partial: 'RESOURCE_WIP'
    @ownerView = new AvatarView {
      size: { width: 25, height: 25 }
    }, resource.owner


  toggleDetails: ->

    @details.toggleClass  'hidden'
    @detailsToggle.toggleClass 'active'
    @toggleClass 'in-detail'


  pistachio: ->

    """
      {{> @detailsToggle}}
      {{> @ownerView}}
      {div.details{#(title)}}
      <div class='clear'></div>
      {{> @details}}
    """
