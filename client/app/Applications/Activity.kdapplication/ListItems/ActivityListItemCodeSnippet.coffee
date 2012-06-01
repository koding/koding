class CodesnipActivityItemView extends ActivityItemChild
  
  constructor:(options, data)->
    options = $.extend
      cssClass    : "activity-item codesnip"
      tooltip     :
        title     : "Code Snippet"
        offset    : 3
        selector  : "span.type-icon"
    ,options
    super options,data
    
    codeSnippetData = @getData().attachments[0]
    codeSnippetData.title = @getData().title

    @codeSnippetView = new CodeSnippetView {}, codeSnippetData

    # log data.meta.tags
    # @tagGroup = new LinkGroup {
    #   group         : data.meta.tags
    #   itemsToShow   : 3
    #   subItemClass  : TagFollowBucketItemView
    # }
    
  click:(event)->
    super
    if $(event.target).is(".activity-item-right-col h3")
      appManager.tell "Activity", "createContentDisplay", @getData()

  viewAppended: ->
    return if @getData().constructor is bongo.api.CCodeSnipActivity
    super()
    @setTemplate @pistachio()
    @template.update()


  pistachio:->
    """
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      {h3{#(title)}}
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      {{> @codeSnippetView}}
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          {time{$.timeago #(meta.createdAt)}}
          <span class='tag-group'>{{ @displayTags #(tags)}}</span>
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """



class CodeSnippetView extends KDCustomHTMLView
  openFileIteration = 0

  syntaxMap = ->
    c_cpp       : "cpp"
    html        : "xml"
    latex       : 'tex'
    markdown    : 'xml'
    powershell  : 'bash'
    coldfusion  : 'xml'
    JSON        : 'javascript'

  syntaxHumanMap = ->
    c_cpp   : "c++"
    coffee  : "coffee-script"

  constructor:(options, data)->
    options.tagName  = "figure"
    options.cssClass = "code-container"
    super
    @unsetClass "kdcustomhtml"

    {content, syntax, title} = data = @getData()

    # @codeView = new NonEditableAceField defaultValue: Encoder.htmlDecode(content), autoGrow: yes, afterOpen: =>
    #   syntax or= 'javascript'
    #   @codeView.setTheme 'merbivore'
    #   @codeView.setSyntax syntax
    # 
    # @codeView.on 'sizes.height.change', ({height}) =>
    #   @$('.wrapper').height height

    syntax or= 'javascript'

    @codeView = new KDCustomHTMLView
      tagName  : "code"
      cssClass : syntaxMap()[syntax] or syntax
      partial  : content
    
    @codeView.unsetClass "kdcustomhtml"
    
    @syntaxMode = new KDCustomHTMLView
      tagName  : "strong"
      partial  : syntaxHumanMap()[syntax] or syntax

    @saveButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "save"
      callback  : ->
        new KDNotificationView
          title     : "Currently disabled!"
          type      : "mini"
          duration  : 2500
        
        # CodeSnippetView.emit 'CodeSnippetWantsSave', data

    @openButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "open"
      callback  : ->
        fileName      = "localfile:/#{title}"
        file          = FSHelper.createFileFromPath fileName
        file.contents = Encoder.htmlDecode(content)
        appManager.openFileWithApplication file, 'Ace'

    @copyButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "select-all"
      callback  : =>
        @utils.selectText @codeView.$()[0]

  viewAppended: ->
    snipView = @
    syntax = syntaxMap()[unmapped = @getData().syntax] or unmapped
    @setTemplate @pistachio()
    @template.update()
    twOptions = (title) ->
      title : title, placement : "above", offset : 3, delayIn : 300, html : yes, animate : yes
    requirejs (['js/highlightjs/highlight.js']), ->
      requirejs (["highlightjs/languages/#{syntax}"]), ->
        try
          hljs.compileModes()
          hljs.highlightBlock snipView.codeView.$()[0],'  '
        catch err
          console.warn "Error applying highlightjs syntax #{syntax}:", err
    
    @saveButton.$().twipsy twOptions("Save")
    @copyButton.$().twipsy twOptions("Select all")
    @openButton.$().twipsy twOptions("Open")

  pistachio:->
    """
    {pre{> @codeView}}
    <div class='button-bar'>{{> @saveButton}}{{> @openButton}}{{> @copyButton}}</div>
    {{> @syntaxMode}}
    """
  