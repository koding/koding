fs = require 'fs'


getHookSuiteName = (type) ->

  hookDir = process.env.TEST_SUITE_HOOK_DIR
  { TEST_GROUP, TEST_SUITE } = process.env

  return "#{hookDir}/#{TEST_GROUP}_#{TEST_SUITE}_#{type}"


module.exports =


  before: (done) ->

    hookFilePath = getHookSuiteName 'after'
    fs.writeFile hookFilePath, '', done


  after: (done) ->

    hookFilePath = getHookSuiteName 'after'
    fs.writeFile hookFilePath, '', done
