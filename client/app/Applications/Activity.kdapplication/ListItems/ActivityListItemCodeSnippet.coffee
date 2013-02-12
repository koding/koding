class CodesnipActivityItemView extends ActivityItemChild

  constructor:(options, data)->
    options = $.extend
      cssClass    : "activity-item codesnip"
      tooltip     :
        title     : "Code Snippet"
        offset    :
          top     : 3
          left    : -5
        selector  : "span.type-icon"
    ,options
    super options,data

    codeSnippetData = @getData().attachments[0]
    codeSnippetData.title = @getData().title

    @codeSnippetView = new CodeSnippetView {}, codeSnippetData

    # @codeShareBoxView = new CodeShareBox
    #   allowEditing:no
    #   allowClosing:no
    #   hideTabs:yes
    # ,data

    # log data.meta.tags
    # @tagGroup = new LinkGroup {
    #   group         : data.meta.tags
    #   itemsToShow   : 3
    #   itemClass  : TagFollowBucketItemView
    # }

  render:->
    super()

    codeSnippetData = @getData().attachments[0]
    codeSnippetData.title = @getData().title

    @codeSnippetView.setData codeSnippetData
    @codeSnippetView.render()


  click:(event)->

    super

    if $(event.target).is(".activity-item-right-col h3")
      KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", state:@getData()
      #KD.getSingleton("appManager").tell "Activity", "createContentDisplay", @getData()

  viewAppended: ->
    return if @getData().constructor is KD.remote.api.CCodeSnipActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    @codeSnippetView.$().hover =>
      @enableScrolling = setTimeout =>
        @codeSnippetView.codeView.setClass 'scrollable-y'
        @codeSnippetView.setClass 'scroll-highlight out'

      ,1000
    , =>
      clearTimeout @enableScrolling
      @codeSnippetView.codeView.unsetClass 'scrollable-y'
      @codeSnippetView.unsetClass 'scroll-highlight out'

  pistachio:->
    # {{> @codeShareBoxView}}
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      {h3{#(title)}}
      <p class='context'>{{@utils.applyTextExpansions #(body), yes}}</p>
      {{> @codeSnippetView}}
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          {time{$.timeago #(meta.createdAt)}}
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """

class CodeSnippetView extends KDCustomHTMLView

  openFileIteration = 0

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

    hjsSyntax = __aceSettings.aceToHighlightJsSyntaxMap[syntax]

    @codeView = new KDCustomHTMLView
      cssClass  : ''
      tagName   : 'code'
      pistachio : '{{#(content)}}'
    , data

    @syntaxMode = new KDCustomHTMLView
      tagName  : "strong"
      partial  : __aceSettings.syntaxAssociations[syntax]?[0] or syntax ? "text"

    @saveButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "save"
      tooltip   :
        title   : 'Save'
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
      tooltip   :
        title   : 'Open'
      callback  : ->
        fileName      = "localfile:/#{title}"
        file          = FSHelper.createFileFromPath fileName
        file.contents = Encoder.htmlDecode(content)
        file.syntax   = syntax
        KD.getSingleton("appManager").openFileWithApplication file, 'Ace'

    @copyButton = new KDButtonView
      title     : ""
      style     : "dark"
      icon      : yes
      iconOnly  : yes
      iconClass : "select-all"
      tooltip   :
        title   : 'Select All'
      callback  : =>
        @utils.selectText @codeView.$()[0]

  render:->

    super()
    @codeView.setData @getData()
    @codeView.render()
    @applySyntaxColoring()

  applySyntaxColoring:( syntax = @getData().syntax)->

    snipView  = @

    try
      hljs.highlightBlock snipView.codeView.$()[0], '  '
    catch err
      warn "Error applying highlightjs syntax #{syntax}:", err

  viewAppended: ->

    @setTemplate @pistachio()
    @template.update()

    @applySyntaxColoring()

  pistachio:->
    """
    <div class='kdview'>
      {pre{> @codeView}}
      <div class='button-bar'>{{> @saveButton}}{{> @openButton}}{{> @copyButton}}</div>
    </div>
    {{> @syntaxMode}}
    """
