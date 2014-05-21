class CommentListPreviousLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'list-previous-link', options.cssClass

    super options, data


  click: -> @emit 'List'


  update: ->

    {replies, repliesCount} = @getData()
    listedCount = @getDelegate().getItemCount() or replies.length
    count       = Math.min (repliesCount - listedCount), 10

    if count > 0
    then @updatePartial "Show previous #{count} repl#{if count is 1 then 'y' else 'ies'}"
    else @hide()


  viewAppended: ->

    {replies, repliesCount} = @getData()

    if repliesCount <= replies.length
    then @hide()
    else @update()
