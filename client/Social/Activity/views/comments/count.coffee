class ActivityCommentCount extends CustomLinkView

  viewAppended: ->

    super

    {repliesCount} = @getData()
    if repliesCount then @show() else @hide()


  pistachio: -> '{{ #(repliesCount)}}'
