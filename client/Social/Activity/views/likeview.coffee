class ActivityLikeView extends JView

  constructor: (options = {}, data) ->

    options.tagName            or= 'span'
    options.cssClass           or= 'like-view'
    options.tooltipPosition    or= 'se'
    options.useTitle            ?= yes

    super options, data


  viewAppended: ->

    data = @getData()

    @link = new ActivityLikeLink {}, data

    @count = new ActivityLikeCount
      tooltip     :
        gravity   : options.tooltipPosition
        title     : ""
    , data


  pistachio: ->

    "{{> @link}}{{> @count}}"
