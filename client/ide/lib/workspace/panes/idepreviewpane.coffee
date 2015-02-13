kd = require 'kd'
IDEPane = require './idepane'
PreviewerView = require 'viewer/previewerview'
module.exports = class IDEPreviewPane extends IDEPane

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'preview-pane', options.cssClass
    options.paneType = 'preview'

    super options, data

    viewerOptions =
      delegate    : this
      params      :
        path      : @getOptions().url

    delete viewerOptions.params.path  unless viewerOptions.params.path

    @addSubView @previewer = new PreviewerView viewerOptions

    @previewer.on 'ViewerLocationChanged', (newLocation) =>
      @setOption 'url', newLocation
      @emit 'LocationChanged', newLocation

  serialize: ->
    {url, paneType} = @getOptions()

    return { url, paneType, @hash }
