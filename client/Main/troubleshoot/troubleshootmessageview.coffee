class TroubleshootMessageView extends KDCustomHTMLView

  constructor: (options, data) ->
    super options, data
    @hide()
    @views = {}
    @count = 0

  addItem: (item, message) ->
    @show()
    @count++
    {status, name} = item
    @addSubView @views[name] = new KDCustomHTMLView
      tagName: "div"
      cssClass: "status-message #{status}"
      partial: "* #{message}"

  removeItem: (item) ->
    @count--
    {name} = item
    @hide()  unless @count
    @views[name].destroy()
    delete @views[name]