class TagContextMenuItem extends JContextMenuItem
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "tag-context-menu-item", options.cssClass
    super options, data

  viewAppended: JView::viewAppended

  setTemplate: JView::setTemplate

  pistachio: ->
    {$suggest, $deleted} = @getData()

    if $suggest
      """Suggest <span class="ttag">#{Encoder.XSSEncode $suggest}</span> as a new topic?"""
    else if $deleted
      """You can not tag your post with <span class="ttag">#{Encoder.XSSEncode $deleted}</span>"""
    else
      "{{#(title)}}"
