argv = require('minimist') process.argv
site = SITE_NAME or argv.site or 'landing'
base = "#{__dirname}/.."

module.exports =
  STYLES_PATH     : ["#{base}/site.#{site}/styl/*.styl"]
  COFFEE_PATH     : ["#{base}/site.#{site}/coffee/**/*.coffee"]
  BROWSERFIY_PATH : ["#{base}/site.#{site}/coffee/main.coffee"]
  INDEX_PATH      : ["#{base}/site.#{site}/index.html"]
  BUILD_PATH      : "#{base}/static/a/site.#{site}"
