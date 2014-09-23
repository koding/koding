argv = require('minimist') process.argv

site = argv.site or 'landing'
base = "#{__dirname}/.."

module.exports =
  STYLES_PATH     : ["#{base}/#{site}/styl/*.styl"]
  COFFEE_PATH     : ["#{base}/#{site}/coffee/**/*.coffee"]
  BROWSERFIY_PATH : ["#{base}/#{site}/coffee/main.coffee"]
  INDEX_PATH      : ["#{base}/#{site}/index.html"]
  BUILD_PATH      : argv.outputDir ? "#{base}/static/site.#{site}/a/out"
