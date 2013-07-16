class OpenWithModalItem extends JView

  constructor: (options= {}, data) ->

    options.cssClass = "app"

    super options, data

    @img = KD.utils.getAppIcon @getData()

    @setClass "not-supported" unless @getOptions().supported

    @on "click", =>
      delegate = @getDelegate()
      delegate.selectedApp.unsetClass "selected" if delegate.selectedApp
      @setClass "selected"
      delegate.selectedApp = @

  pistachio: ->
    data = @getData()
    """
      {{> @img }}
      <div class="app-name">#{data.name}</div>
    """