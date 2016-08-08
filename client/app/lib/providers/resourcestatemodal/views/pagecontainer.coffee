kd = require 'kd'

module.exports = class PageContainer extends kd.TabView

  constructor: (options = {}, data) ->

    options.hideHandleContainer = yes

    super options, data


  appendPages: (pages...) ->

    paneData = pages.map (page) -> { view : page, lazy : yes }
    @createPanes paneData


  showPage: (page) ->

    pane = _pane for _pane in @panes when _pane.options.view is page
    @showPane pane
    page.emit 'PageDidShow'
    @emit 'PageDidShow', page
