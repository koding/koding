class TagContextMenuItem extends JContextMenuItem
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "tag-context-menu-item", options.cssClass
    super options, data

  pistachio: ->
    {$suggest, $deleted} = @getData()
    if $suggest
      """Suggest <span class="ttag">{{#($suggest)}}</span> as a new topic?"""
    else if $deleted
      """You can not tag your post with <span class="ttag">{{#($deleted)}}</span>"""
    else
      "{{#(title)}}"
