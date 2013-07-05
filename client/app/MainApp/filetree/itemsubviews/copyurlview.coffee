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

        path  = FSHelper.plainPath path
        match = path.match ///home/(\w+)/Web/(.*)///
        return  unless match
        [rest..., user, pathrest] = match

        if /^shared-/.test hostname
          subdomain = unless user is KD.nick() then "" else "#{user}."
        else
          subdomain = ''

        @publicPath = "#{subdomain}#{domains.first}/#{pathrest}"
        @inputUrl.setValue "http://#{@publicPath}"

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