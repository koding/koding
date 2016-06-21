fs = require 'fs'
path = require 'path'


getHookSuiteName = (type) ->

  hookDir = process.env.TEST_SUITE_HOOK_DIR
  { TEST_GROUP, TEST_SUITE } = process.env

  return "#{hookDir}/#{TEST_GROUP}_#{TEST_SUITE}_#{type}"


awsKeyPath = path.resolve __dirname, '../../vault/config/aws/worker_ci_test_key.json'

module.exports =

  awsKey: require awsKeyPath


  before: (done) ->

    hookFilePath = getHookSuiteName 'after'
    fs.writeFile hookFilePath, '', done


  after: (done) ->

    hookFilePath = getHookSuiteName 'after'
    fs.writeFile hookFilePath, '', done
