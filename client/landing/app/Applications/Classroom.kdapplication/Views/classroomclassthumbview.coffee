class ClassroomClassThumbView extends KDView

  constructor: (options = {}, data) ->

    options.tagName = "figure"

    super options, data

    @addSubView @loader = new KDLoaderView
      size    :
        width : 40

    @fetchManifest()

  fetchManifest: ->
    manifestURL = "#{@getOptions().cdnRoot}/#{@getData()}.kdclass/manifest.json"
    KD.getSingleton("kiteController").run "curl -s #{manifestURL}", (err, res) =>
      log err, res

  createElements: ->
  #   devModeOptions = {}
  #   if data.devMode
  #     devModeOptions.cssClass = "top-badge gray"
  #     devModeOptions.partial  = "Dev Mode"

  #   @devMode     = new KDCustomHTMLView devModeOptions
  #   @icon        = new KDCustomHTMLView
  #     tagName    : "img"
  #     attributes :
  #       src      : "#{@cdnRoot}/#{@getData().icns['128']}"

  #   @deleteIcon  = new KDCustomHTMLView
  #     tagName    : "span"
  #     cssClass   : "icon delete"
  #     click      : ->
  #       log "sadasdas"

  viewAppended: ->
    super
    @loader.show()

  # pistachio: ->
  #   data   = @getData()
  #   return """
  #     {{> @devMode}}
  #     <p>{{> @icon}}</p>
  #     <div class="icon-container">
  #       {{> @deleteIcon}}
  #     </div>
  #     <cite>
  #       <span>#{data.name}</span>
  #       <span>#{data.version}</span>
  #     </cite>
  #   """
