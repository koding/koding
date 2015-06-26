kd            = require 'kd'
remote        = require('app/remote').getInstance()

JView         = require 'app/jview'
StackRepoItem = require './stackrepoitem'


module.exports = class StackRepoUserItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'repo-user-item', options.cssClass

    super options, data

    {repos, avatar_url} = @getData()

    avatar_url   ?= repos.first?.owner.avatar_url

    @gravatarView = new kd.CustomHTMLView
      tagName     : 'img'
      attributes  :
        src       : avatar_url
      cssClass    : 'gravatar'

    @gravatarView.hide()  unless avatar_url

    @loader       = new kd.LoaderView
      size        :
        width     : 40
        height    : 40
      cssClass    : 'hidden'


  toggleRepoListView: ->

    return @repoListView.toggleClass 'hidden'  if @repoListView

    delegate       = @getDelegate()

    controller    = new kd.ListViewController
      viewOptions :
        itemClass : StackRepoItem

    listView      = controller.getListView()

    delegate.forwardEvent listView, 'RepoSelected'

    @addSubView @repoListView = controller.getView()

    @fetchRepos (repos) ->
      controller.replaceAllItems repos


  fetchRepos: (callback) ->

    { repos, err, login } = @getData()

    @addErrorView err      if err
    return callback repos  if repos

    @repoListView.hide()
    @loader.show()

    remote.api.Github.api
      method  : 'repos.getFromOrg'
      options :
        org   : login
    , (err, repos) =>

      @loader.hide()
      @repoListView.show()

      if err then @addErrorView err
      else callback repos


  addErrorView: (err) ->
    @repoListView.addSubView new kd.CustomHTMLView
      partial: err.message


  click: (event) ->

    return  unless event.target.classList.contains 'repo-user-item'

    @toggleClass 'active'
    @toggleRepoListView()


  pistachio: ->
    "{{> @gravatarView}}{div.user-title{#(login)}}{span.active-link{}}{{> @loader}}"
