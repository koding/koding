class InboxMessageListController extends KDListViewController

  constructor:->
    super
    @selectedMessages = {}

  loadMessages:(callback, continueLoading = no)->

    options =
      limit       : 10
      sort        :
        timestamp : -1
    options.skip = @getItemCount() if continueLoading

    KD.whoami().fetchMail options, (err, messages)=>
      @removeAllItems() if not continueLoading
      @loadMoreMessagesItem?.destroy()
      @instantiateListItems messages

      if messages.length >= 10
        @getListView().addItemView @loadMoreMessagesItem = new LoadMoreMessagesItem
          click:=>
            if not @loadMoreMessagesItem.isWorking?
              @loadMoreMessagesItem.isWorking = yes
              @loadMoreMessagesItem.updatePartial 'Loading...'
              @loadMessages callback?, yes

      callback?()
