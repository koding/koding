argv = require('minimist') process.argv
site = SITE_NAME or argv.site or 'landing'
base = __dirname.replace '/gulptasks', ''

module.exports =
  STYLES_PATH     : [
                     "#{base}/node_modules/kd.js/dist/kd.css"
                     "#{base}/site.#{site}/styl/*.styl"
                     "!#{base}/site.#{site}/styl/sprite@*x.styl"
                    ]
  SPRITES_PATH    : ["#{base}/site.#{site}/sprites*/**/*"]
  COFFEE_PATH     : ["#{base}/site.#{site}/coffee/**/*.coffee"]
  LIBS_PATH       : ["#{base}/site.#{site}/libs/**/*.js"]
  BROWSERFIY_PATH : ["#{base}/site.#{site}/coffee/main.coffee"]
  INDEX_PATH      : ["#{base}/site.#{site}/index.html"]
  BUILD_PATH      :  "#{base}/static/a/site.#{site}"
  IMAGE_PATH      : ["#{base}/static/a/site.#{site}/**/*"]
  CONFIG_PATH     :  "#{base}/../.config.json"
