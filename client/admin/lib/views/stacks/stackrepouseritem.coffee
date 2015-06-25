kd            = require 'kd'
JView         = require 'app/jview'
StackRepoItem = require './stackrepoitem'


module.exports = class StackRepoUserItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'repo-user-item', options.cssClass

    super options, data

    {repos} = @getData()

    gravatarUrl   = repos.first?.owner.avatar_url

    @gravatarView = new kd.CustomHTMLView
      tagName     : 'img'
      attributes  :
        src       : gravatarUrl
      cssClass    : 'gravatar'

    @gravatarView.hide()  unless gravatarUrl


  toggleRepoListView: ->

    return @repoListView.toggleClass 'hidden'  if @repoListView

    { repos, err } = @getData()
    delegate       = @getDelegate()

    controller    = new kd.ListViewController
      viewOptions :
        itemClass : StackRepoItem

    listView      = controller.getListView()

    delegate.forwardEvent listView, 'RepoSelected'

    @addSubView @repoListView = controller.getView()

    if err?
      @repoListView.addSubView new kd.CustomHTMLView
        partial: err.message
    else
      controller.replaceAllItems repos


  click: (event) ->

    return  unless event.target.classList.contains 'repo-user-item'

    @toggleClass 'active'
    @toggleRepoListView()


  pistachio: ->
    "{{> @gravatarView}}{div.user-title{#(username)}}{span.active-link{}}"
