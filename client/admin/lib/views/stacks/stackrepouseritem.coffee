kd            = require 'kd'
JView         = require 'app/jview'
StackRepoItem = require './stackrepoitem'


module.exports = class StackRepoUserItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'repo-user-item', options.cssClass

    super options, data

    {repos} = @getData()

    @gravatarView = new kd.CustomHTMLView
      tagName     : 'img'
      attributes  :
        src       : repos.first?.owner.avatar_url
      cssClass    : 'gravatar'


  toggleRepoListView: ->

    return @repoListView.toggleClass 'hidden'  if @repoListView

    { repos } = @getData()

    controller          = new kd.ListViewController
      viewOptions       :
        itemClass       : StackRepoItem

    controller.replaceAllItems repos

    @addSubView @repoListView = controller.getView()


  click: (event) ->

    return  if (event.target.className.indexOf 'repo-user-item') <= 0

    @toggleClass 'active'
    @toggleRepoListView()


  pistachio: ->
    "{{> @gravatarView}}{div.title{#(username)}}{span.active-link{}}"
