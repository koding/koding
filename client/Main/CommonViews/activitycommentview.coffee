class ActivityCommentView extends JView

  constructor:(options = {}, data)->

    options.charLimit or= 15
    super options, data

    {body} = @getData()
    @trimmedBody = trimComment body, options.charLimit

  pistachio: ->
    "#{@trimmedBody}"

  trimComment= (comment, charLimit) ->
    if comment.length > charLimit then "\"#{comment.substring(0, charLimit)}...\""
    else comment