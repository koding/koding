[_,_,start,count] = (Number val for val in process.argv)

runBatch = require './runbatch'

@['test first 100'] = (test)->
  runBatch 1, 100, (report)->
    test.ok report?.successCount is 100, 'batch of 100, starting with #1'
    test.done()

@['test middle 450'] = (test)->
  runBatch 333, 450, (report)->
    test.ok report?.successCount is 450, 'batch of 100, starting with #1'
    test.done()