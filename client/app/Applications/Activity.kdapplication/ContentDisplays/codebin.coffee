class ContentDisplayCodeBin extends ContentDisplayStatusUpdate

  constructor:(options = {}, data)->

    options.tooltip or=
      title     : "Code Bin"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    @unsetClass 'status'
    @setClass 'codebin'

    @codeBinHTMLView = new CodeSnippetView {},data.attachments[0]
    @codeBinCSSView = new CodeSnippetView {},data.attachments[1]
    @codeBinJSView = new CodeSnippetView {},data.attachments[2]

    @codeBinResultView = new CodeBinResultView {} ,data
    @codeBinResultView.hide()

    @codeBinResultButton = new KDButtonView
      title: "Run this"
      cssClass:"clean-gray result-button"
      click:=>
        @codeBinResultView.show()
        @codeBinResultView.emit "CodeBinSourceHasChanges"

    @codeBinForkButton = new KDButtonView
      title: "Fork this"
      cssClass:"clean-gray fork-button"
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
      {{> @codeBinResultButton}}
      {{> @codeBinForkButton}}
      {{> @codeBinResultView}}
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
