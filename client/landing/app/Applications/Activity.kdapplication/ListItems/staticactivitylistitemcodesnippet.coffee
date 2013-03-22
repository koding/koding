class StaticCodesnipActivityItemView extends StaticActivityItemChild

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


  render:->
    super()

    codeSnippetData = @getData().attachments[0]
    codeSnippetData.title = @getData().title

    @codeSnippetView.setData codeSnippetData
    @codeSnippetView.render()

  viewAppended: ->
    super
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
    """
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      {h3{#(title)}}
      <p class='context'>{{@utils.applyTextExpansions #(body), yes}}</p>
      {{> @codeSnippetView}}
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          {time{ @formatCreateDate #(meta.createdAt)}}
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
    </div>
    """