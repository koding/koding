argv = require('minimist') process.argv

module.exports =
  STYLES_PATH     : ["#{__dirname}/../landing/styl/*.styl"]
  COFFEE_PATH     : ["#{__dirname}/../landing/coffee/**/*.coffee"]
  BROWSERFIY_PATH : ["#{__dirname}/../landing/coffee/main.coffee"]
  INDEX_PATH      : ["#{__dirname}/../landing/index.html"]
  SERVER_FILE     : "#{__dirname}/../server/server.coffee"
  SERVER_PATH     : ["#{__dirname}/../server/**/*.coffee"]
  BUILD_PATH      : argv.outputDir ? "#{__dirname}/../static/a/out"
