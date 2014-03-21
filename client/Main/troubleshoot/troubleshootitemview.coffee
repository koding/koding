class TroubleshootItemView extends KDCustomHTMLView

  constructor: (options, data) ->
    options.cssClass ?= "hidden"
    super options, data

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes

    @getData().once "healthCheckStarted", startCheck.bind this

    @getData().once "healthCheckCompleted", completeCheck.bind this

    @getData().on "recoveryStarted", startCheck.bind this

    @getData().on "recoveryCompleted", completeCheck.bind this

    @status = new KDCustomHTMLView
      tagName   : "strong"
      pistachio : "{{#(status)}}"
      cssClass  : "status"
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

  startCheck: ->
    @show()
    @loader.show()
    @status.render()
    @status.unsetClass "fail success"

  completeCheck: ->
    @loader.hide()
    @status.render()
    {status} = @getData()
    @status.unsetClass "fail success"
    @status.setClass "#{status}"

  destroy: ->
    @off "recoveryCompleted"
    @off "recoveryStarted"
    super