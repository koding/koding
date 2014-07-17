class ActivityLikeView extends JView

  constructor: (options = {}, data) ->

    options.tagName            or= 'span'
    options.cssClass           or= 'like-view'
    options.tooltipPosition    or= 'se'
    options.useTitle            ?= yes

    super options, data

    @link = new ActivityLikeLink {}, data

  pistachio: -> "{{> @link}}"
