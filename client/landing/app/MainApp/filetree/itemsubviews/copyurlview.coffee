class NCopyUrlView extends JView

  constructor: ->
    super

    {path}      = @getData()
    hostname    = FSHelper.getVMNameFromPath path
    @publicPath = FSHelper.isPublicPath path

    @inputUrlLabel  = new KDLabelView
      cssClass      : 'public-url-label'
      title         : 'Public URL'
      click         : => @focusAndSelectAll()

    @inputUrl       = new KDInputView
      label         : @inputUrlLabel
      cssClass      : 'public-url-input'

    KD.getSingleton('vmController').fetchVMDomains hostname, (err, domains)=>
      if domains?.length > 0 and not err
        @publicPath = domains.first
        @inputUrl.setValue (FSHelper.plainPath path).replace \
          ////home/(.*)/Web/(.*)///, "http://#{@publicPath}/$2"

  focusAndSelectAll:->
    @inputUrl.setFocus()
    @inputUrl.selectAll()

  viewAppended:->
    @setClass "copy-url-wrapper"
    super

  pistachio:->
    unless @publicPath
      """
      <div class="public-url-warning">This #{@getData().type} can not be reached over a public URL</div>
      """
    else
      """
      {{> @inputUrlLabel}}
      {{> @inputUrl}}
      """