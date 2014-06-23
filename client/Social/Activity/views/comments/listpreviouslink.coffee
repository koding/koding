class CommentListPreviousLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'list-previous-link', options.cssClass

    super options, data


  click: -> @emit 'List'


  update: ->

    {replies, repliesCount} = @getData()
    listedCount = @getDelegate().getItemCount() or replies.length
    count       = Math.min (repliesCount - listedCount), 10

    partial = if listedCount + count < repliesCount
    then "Show #{count} of #{repliesCount - listedCount} previous repl#{if count is 1 then 'y' else 'ies'}"
    else "Show previous #{count} repl#{if count is 1 then 'y' else 'ies'}"

    if count > 0
    then @updatePartial partial
    else @hide()


  viewAppended: ->

    {replies, repliesCount} = @getData()

    if repliesCount <= replies.length
    then @hide()
    else @update()
