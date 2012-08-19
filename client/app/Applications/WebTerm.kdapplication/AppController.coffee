class WebTermController extends AppController
  constructor: (options = {}, data) ->
    options.view = new WebTermView
    super options, data

  bringToFront: ->
    super name: 'WebTerm'

WebTerm = {}
