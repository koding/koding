kd = require 'kd'
Promise = require 'bluebird'

module.exports = class BasePageController extends kd.Controller

  registerPages: (pages) ->

    @pages = pages

    { container } = @getOptions()
    for page in @pages when page instanceof kd.View
      container.addSubView page

    @hide()
    @emit 'ready'


  setCurrentPage: (page) ->

    return  if page is @currentPage

    p = new Promise (resolve) =>
      resolve()  if page instanceof kd.View
      page.ready resolve

    p.then =>
      @currentPage?.hide()
      page.show()
      @currentPage = page
      @emit 'PageChanged'


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
