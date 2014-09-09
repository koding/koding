class CommentLoadTest extends LoadTest
  @analyze: (pane) ->

    allItemsInDom = pane.controller.getListItems()

    data = null
    allItemsInDom.filter (item) ->
      return /\|--\|/.test item.data.body
    .forEach (val, key) ->
      body = val.data.body
      shit = body.split '|--|'
      message = shit[0]
      [batchId, nick, batchCount, interval, index] = shit[1].split '-'

      data = {} unless data
      data["#{nick}_#{batchId}"]            or= {}
      data["#{nick}_#{batchId}"].batchCount or= batchCount
      data["#{nick}_#{batchId}"].messages   or= []

      data["#{nick}_#{batchId}"].messages.push
        seenMessage     : message
        originalMessage : LoadTest.testData[index %% 100].body
        valid           : message is LoadTest.testData[index %% 100].body
        arrival         : 0
        departure       : index*interval+batchId

    console.log data

