class ContentDisplayCodeBin extends ContentDisplayStatusUpdate

  constructor:(options = {}, data)->

    options.tooltip or=
      title     : "Code Bin"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    @unsetClass 'status'
    @setClass 'codebin'

    @codeBinHTMLView = new CodeBinSnippetView {},data.attachments[0]
    @codeBinCSSView = new CodeBinSnippetView {},data.attachments[1]
    @codeBinJSView = new CodeBinSnippetView {},data.attachments[2]

    @codeBinResultView = new CodeBinResultView {} ,data
    @codeBinResultView.hide()

    @codeBinResultButton = new KDButtonView
      title: "Run this"
      cssClass:"clean-gray result-button"
      click:=>
        @codeBinResultButton.setTitle "Reset"
        @codeBinResultView.show()
        @codeBinCloseButton.show()
        @codeBinResultView.emit "CodeBinSourceHasChanges", @getData()

    @codeBinCloseButton = new KDButtonView
      title: "Close"
      cssClass:"clean-gray hidden"
      click:=>
        @codeBinResultView.hide()
        @codeBinResultView.resetResultFrame()
        @codeBinResultButton.setTitle "Run"
        @codeBinCloseButton.hide()

    @codeBinForkButton = new KDButtonView
      title: "Fork this Code Share"
      cssClass:"clean-gray fork-button"
      disabled: yes
      click:=>


  viewAppended: ->
    return if @getData().constructor is bongo.api.CCodeBinActivity
    super()
    # @setTemplate @pistachio()
    # @template.update()

    maxHeight = 30
    views = [@codeBinJSView,@codeBinCSSView,@codeBinHTMLView]

    for view in views
      if view.getHeight()>maxHeight
        maxHeight = view.getHeight()

    @$("pre.subview").css height:maxHeight

  pistachio:->
    """
    <span>
      {{> @avatar}}
      <span class="author">AUTHOR</span>
    </span>
    <div class='activity-item-right-col'>

      <h3>{{#(title)}}</h3>
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      <div class="code-bin-source">
      {{> @codeBinHTMLView}}
      {{> @codeBinCSSView}}
      {{> @codeBinJSView}}
      </div>
      {{> @codeBinResultView}}
      {{> @codeBinResultButton}}
      {{> @codeBinCloseButton}}
      {{> @codeBinForkButton}}
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
