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

    { repos, err, login } = @getData()

    controller = @createListController()
    listView   = controller.getListView()

    delegate   = @getDelegate()
    delegate.forwardEvent listView, 'RepoSelected'

    @addSubView @repoListView = controller.getView()
    @setErrorView err  if err

    @_page = 1

    if repos
      controller.replaceAllItems repos
    else
      controller.showLazyLoader()

      @fetchRepos (err, repos) =>
        kd.utils.defer controller.bound 'hideLazyLoader'

        if err then @setErrorView err
        else controller.replaceAllItems repos


    @followLazyLoad controller


  fetchRepos: (callback) ->

    { repos, login } = @getData()

    options     =
      page      : @_page
      sort      : 'pushed'
      direction : 'desc'

    if repos
      method = 'repos.getFromUser'
      options.user = login
    else
      method = 'repos.getFromOrg'
      options.org  = login

    remote.api.Github.api {method, options}, callback


  createListController: ->

    new kd.ListViewController
      itemClass           : StackRepoItem
      useCustomScrollView : yes
      lazyLoadThreshold   : 10
      lazyLoaderOptions   :
        spinnerOptions    :
          loaderOptions   : shape: 'spiral', color: '#a4a4a4'
          size            : width: 20, height: 20
        partial           : ''


  followLazyLoad: (controller) ->

    busy = no

    controller.on 'LazyLoadThresholdReached', kd.utils.debounce 300, =>

      return  if busy

      busy = yes
      @_page++

      @fetchRepos (err, items) =>

        kd.utils.defer controller.bound 'hideLazyLoader'

        busy = no

        return @setErrorView err  if err
        return  if items.length is 0

        @_errorView?.hide()
        controller.instantiateListItems items



  setErrorView: (err) ->

    if @_errorView
      @_errorView.updatePartial err.message
      @_errorView.show()
      return

    @repoListView.addSubView @_errorView = new kd.CustomHTMLView
      partial  : err.message
      cssClass : 'error-view'


  click: (event) ->

    return  unless event.target.classList.contains 'repo-user-item'

    @toggleClass 'active'
    @toggleRepoListView()


  pistachio: ->
    "{{> @gravatarView}}{div.user-title{#(login)}}{span.active-link{}}{{> @loader}}"
