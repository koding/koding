var child_process = require('child_process')
var path = require('path')
var fs = require('fs')
var chalk = require('chalk')

var logProgress = require('./log-progress')

var configFile = path.join(__dirname, '../.config.json')

var debugLog = chalk.blue('create-bongo-models') + ': write bongo schema to ' + configFile

var end = logProgress(debugLog)

child_process.exec('node ' + __dirname + '/get-bongo-schema.js', function(err, result) {
  if (err) throw err

  var configData = {}
  if (fs.existsSync(configFile)) {
    configData = require(configFile)
  }

  configData['schema'] = JSON.parse(result)

  fs.writeFile(configFile, JSON.stringify(configData))

  end()
})


