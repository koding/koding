kd = require 'kd'
async = require 'async'
Promise = require 'bluebird'

module.exports = class BasePageController extends kd.Controller


  constructor: (options, data) ->

    super options, data
    @createLoader()


  createLoader: ->

    { container, showLoader, loaderOptions } = @getOptions()
    return  unless showLoader

    loaderOptions ?= {}
    loaderOptions.showLoader ?= yes
    loaderOptions.label      ?= 'Loading...'

    { label } = loaderOptions
    delete loaderOptions.label

    @loader = new kd.CustomHTMLView
      cssClass : 'loader-container'
      partial  : "<div class='loader-text'>#{label}</div>"
    @loader.addSubView new kd.LoaderView loaderOptions

    container.addSubView @loader
    @setCurrentPage @loader


  registerPages: (pages) ->

    @pages = pages
    queue  = []

    { container } = @getOptions()
    for page in @pages
      if page instanceof kd.View
        page.hide()
        container.addSubView page
      else
        queue.push do (page) ->
          (next) -> page.ready next

    @pages.push @loader  if @loader

    async.parallel queue, => @emit 'ready'


  _setCurrentPage: (page) ->

    @currentPage?.hide()
    page.show()
    @currentPage = page
    @emit 'PageChanged'


  setCurrentPage: (page) ->

    return  if page is @currentPage
    return @_setCurrentPage page  if page.readyState or page instanceof kd.View

    page.ready @lazyBound '_setCurrentPage', page


  show: ->

    @setCurrentPage @pages?.first


  hide: ->

    return  unless @pages

    page.hide() for page in @pages
    @currentPage = null


  destroy: ->

    super

    return  unless @pages
    page.destroy() for page in @pages
