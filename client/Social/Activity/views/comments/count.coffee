class ActivityCommentCount extends CustomLinkView

  viewAppended: ->

    super

    @toggle()


  toggle: ->

    {repliesCount} = @getData()
    if repliesCount then @show() else @hide()


  render: ->

    @toggle()

    super


  pistachio: -> '{{ #(repliesCount)}}'
