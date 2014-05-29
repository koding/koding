class PreviewPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'preview-pane', options.cssClass

    super options, data

    viewerOptions =
      delegate    : this
      params      :
        path      : @getOptions().url

    delete viewerOptions.params.path  unless viewerOptions.params.path

    @previewer = new PreviewerView viewerOptions

  pistachio: ->
    "{{> @previewer}}"
