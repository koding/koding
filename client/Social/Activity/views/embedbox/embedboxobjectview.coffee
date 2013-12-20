class EmbedBoxObjectView extends KDView

  viewAppended: JView::viewAppended

  pistachio:->
    objectHtml = @getData().link_embed?.object?.html
    """
    <div class="embed embed-object-view custom-object">
      #{Encoder.htmlDecode objectHtml or ''}
    </div>
    """
