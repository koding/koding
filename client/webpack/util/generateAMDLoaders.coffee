
# These are the dependencies that are using some magic to identify module
# system (e.g AMD, CommonJS, window global, etc.). Since webpack supports both
# `RequireJS` and `CommonJS` at the same time, we are enforcing `CommonJS`
# with `imports` loader by importing `define` as false in those scripts.
AMDModules = [
  /[\/\\]node_modules[\/\\]jquery-mousewheel[\/\\]jquery\.mousewheel\.js$/,
  require.resolve('dateformat')
]

module.exports = generateAMDLoaders = ->

  AMDModules.map (testPath) ->
    return {
      test: testPath
      loader: 'imports-loader?define=>false'
    }
