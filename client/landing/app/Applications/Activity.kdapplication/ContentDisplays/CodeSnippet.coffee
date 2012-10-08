class ContentDisplayCodeSnippet extends ContentDisplayStatusUpdate

  constructor:(options = {}, data)->

    options.tooltip or=
      title     : "Code Snippet"
      offset    : 3
      selector  : "span.type-icon"

    super options, data

    @codeSnippetView = new CodeSnippetView {},@getData().attachments[0]

  pistachio:->

    """
    {{> @header}}
    <h2 class="sub-header">{{> @back}}</h2>
    <div class='kdview content-display-main-section activity-item codesnip'>
      <span>
        {{> @avatar}}
        <span class="author">AUTHOR</span>
      </span>
      <div class='activity-item-right-col'>
        <h3>{{#(title)}}</h3>
        <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
        {{> @codeSnippetView}}
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
    </div>
    """
