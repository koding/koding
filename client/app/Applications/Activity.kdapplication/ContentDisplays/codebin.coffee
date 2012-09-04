class ContentDisplayCodeBin extends ContentDisplayStatusUpdate

  constructor:(options = {}, data)->

    options.tooltip or=
      title     : "Code Bin"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    @unsetClass 'status'
    @setClass 'codebin'

    @codeBinHTMLView = new CodeSnippetView {},@getData().attachments[0]
    @codeBinCSSView = new CodeSnippetView {},@getData().attachments[1]
    @codeBinJSView = new CodeSnippetView {},@getData().attachments[2]

    @codeBinResultView = new CodeBinResultView
      tagName: "iframe"
      attributes:
        srcdoc:"<html><head><style>"+Encoder.htmlDecode(@getData().attachments[1].content)+"</style><script type='text/javascript'>"+Encoder.htmlDecode(@getData().attachments[2].content)+"</script></head><body>"+Encoder.htmlDecode(@getData().attachments[0].content)+"</body></html>"

    ,data

  viewAppended: ->
    return if @getData().constructor is bongo.api.CCodeBinActivity
    super()
    @setTemplate @pistachio()
    @template.update()

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
