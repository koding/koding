class ReplyListViewController extends CommentListViewController

  constructor: (options = {}, data) ->

    options.viewOptions =
      type              : 'replies'
      dataPath          : 'id'
      itemClass         : ReplyListItemView
      itemOptions       :
        delegate        : this
        activity        : data

    super options, data
