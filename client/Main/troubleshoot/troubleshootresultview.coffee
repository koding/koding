class TroubleshootResultView extends KDCustomHTMLView

  constructor: (options, data) ->
    options.cssClass = "troubleshoot-result"
    super options, data