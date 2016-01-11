kd = require 'kd'
CustomLinkView = require 'app/customlinkview'


module.exports = class CommentListPreviousLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'hidden list-previous-link', options.cssClass
    options.attributes =
      testpath         : 'list-previous-link'

    super options, data

    @update()


  update: ->

    {replies, repliesCount} = @getData()
    {linkCopy}              = @getOptions()

    listedCount  = Math.max @getDelegate().getItemCount(), replies?.length
    count        = Math.min (repliesCount - listedCount), 10

    partial = if linkCopy then linkCopy
    else if listedCount + count < repliesCount
    then "Show #{count} of #{repliesCount - listedCount} previous repl#{if count is 1 then 'y' else 'ies'}"
    else "Show previous #{count} repl#{if count is 1 then 'y' else 'ies'}"

    if count > 0
      @updatePartial partial
      @show()
    else
      @emit 'ReachedToTheBeginning'
      @hide()


  viewAppended: ->

    {replies, repliesCount} = @getData()

    if repliesCount <= replies.length
    then @hide()
    else @update()
