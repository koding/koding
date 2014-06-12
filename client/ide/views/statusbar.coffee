class IDE.StatusBar extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'status-bar'

    super options, data

    @addSubView @status = new KDCustomHTMLView
      cssClass: 'status'
