class TroubleshootItemView extends KDCustomHTMLView

  constructor: (options, data) ->
    options.cssClass ?= "hidden"
    super options, data

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes

    @getData().once "healthCheckStarted", =>
      @show()
      @status.render()
      @status.setClass "status"
      # @status.setClass @getData().status

    @getData().once "healthCheckCompleted", =>
      @loader.hide()
      @status.render()
      {status} = @getData()
      @status.setClass "status #{status}"

    @status = new KDCustomHTMLView
      tagName   : "strong"
      pistachio : "{{#(status)}}"
    , @getData()

    {title} = @getOptions()
    @title = new KDCustomHTMLView
      tagName  : "span"
      partial  : "#{title}"
      cssClass : "checker-name"

  viewAppended: ->
    JView::viewAppended.call this

  # instead we need a slowness indicator
  getResponseTime: ->
    responseTime = @getData().getResponseTime()
    unless responseTime is 0
      return "#{responseTime} ms"
    else
      ""

  pistachio:->
    """
      {{> @loader}} {{> @title}} {{> @status }}
    """