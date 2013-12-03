class TagContextMenuItem extends JContextMenuItem
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "tag-context-menu-item", options.cssClass
    super options, data

  pistachio: ->
    if @getData().$suggest
      """Suggest <span class="ttag">{{#($suggest)}}</span> as a new topic?"""
    else
     "{{#(title)}}"
