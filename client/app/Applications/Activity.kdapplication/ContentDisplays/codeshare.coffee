class ContentDisplayCodeShare extends ContentDisplayStatusUpdate

  constructor:(options = {}, data)->

    options.tooltip or=
      title     : "Code Share"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    @unsetClass 'status'
    @setClass 'codeshare'

    @codeShareHTMLView = new CodeShareSnippetView {},data.attachments[0],data
    @codeShareCSSView = new CodeShareSnippetView {},data.attachments[1],data
    @codeShareJSView = new CodeShareSnippetView {},data.attachments[2],data

    @codeShareResultView = new CodeShareResultView {} ,data

    @codeShareContainer = new KDTabView
      cssClass: "code-share-container"

    @codeShareResultPane = new KDTabPaneView
      name:"Code Share"
      cssClass: "result-pane"

    @codeShareResultPane.addSubView @codeShareResultView

    @codeShareHTMLPane = new KDTabPaneView
      name:"HTML"

    @codeShareHTMLPane.addSubView @codeShareHTMLView

    @codeShareCSSPane = new KDTabPaneView
      name:"CSS"

    @codeShareCSSPane.addSubView @codeShareCSSView

    @codeShareJSPane = new KDTabPaneView
      name:"JavaScript"

    @codeShareJSPane.addSubView @codeShareJSView

    @codeShareContainer.addPane @codeShareResultPane
    @codeShareContainer.addPane @codeShareHTMLPane
    @codeShareContainer.addPane @codeShareCSSPane
    @codeShareContainer.addPane @codeShareJSPane

    @codeShareResultPane.hideTabCloseIcon()
    @codeShareHTMLPane.hideTabCloseIcon()
    @codeShareCSSPane.hideTabCloseIcon()
    @codeShareJSPane.hideTabCloseIcon()

    # hover switching enabled by default
    @codeShareContainer.$(".kdtabhandle").hover (event)=>
      $(event.target).closest(".kdtabhandle").click()
    , noop


    @codeShareResultButton = new KDButtonView
      title: "Run Code Share"
      cssClass:"clean-gray result-button"
      click:=>
        @codeShareResultButton.setTitle "Reset Code Share"
        @codeShareResultView.show()
        @codeShareCloseButton.show()
        @codeShareResultView.emit "CodeShareSourceHasChanges", @getData()

    @codeShareCloseButton = new KDButtonView
      title: "Stop and Close Code Share"
      cssClass:"clean-gray hidden"
      click:=>
        @codeShareResultView.hide()
        @codeShareResultView.resetResultFrame()
        @codeShareResultButton.setTitle "Run Code Share"
        @codeShareCloseButton.hide()

    @codeShareForkButton = new KDButtonView
      title: "Fork this Code Share"
      cssClass:"clean-gray fork-button"
      click:=>
        @emit "ContentDisplayWantsToBeHidden"
        @getSingleton('mainController').emit 'ContentDisplayItemForkLinkClicked', data

  viewAppended: ->
    return if @getData().constructor is KD.remote.api.CCodeShareActivity
    super()
    # @setTemplate @pistachio()
    # @template.update()

    maxHeight = 30
    views = [@codeShareJSView,@codeShareCSSView,@codeShareHTMLView]

    for view in views
      if view.getHeight()>maxHeight
        maxHeight = view.getHeight()

    @$("pre.subview").css height:maxHeight

      # {{> @codeShareHTMLView}}
      # {{> @codeShareCSSView}}
      # {{> @codeShareJSView}}
      # </div>
      # {{> @codeShareResultView}}
      # {{> @codeShareResultButton}}
      # {{> @codeShareCloseButton}}
      # {{> @codeShareForkButton}}

  pistachio:->
    """
    <span>
      {{> @avatar}}
      <span class="author">AUTHOR</span>
    </span>
    <div class='activity-item-right-col'>

      <h3>{{#(title)}}</h3>
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      <div class="code-share-source">
      {{> @codeShareContainer}}

      </div>
      {{> @codeShareResultButton}}
      {{> @codeShareCloseButton}}
      {{> @codeShareForkButton}}
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """
