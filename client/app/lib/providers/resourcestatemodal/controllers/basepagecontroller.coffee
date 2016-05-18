kd = require 'kd'

module.exports = class BasePageController extends kd.Controller

  registerPages: (pages) ->

    @pages = pages

    { container } = @getOptions()
    container.addSubView page for page in @pages

    @hide()


  setCurrentPage: (page) ->

    @currentPage?.hide()
    page.show()
    @currentPage = page


  show: ->

    @setCurrentPage @pages.first


  hide: ->

    page.hide() for page in @pages
    @currentPage = null
