class FatihFileFinderPlugin extends FatihPluginAbstract

  constructor: (options = {}, data) ->

    options.name          = "File Finder"
    options.keyword       = "find"
    options.notFoundText  = "This is not the file you're looking for!"

    super options, data

    @on "ListItemClicked", -> @fatihView.destroy()

  action: (keyword) ->
    path    = "/home/#{KD.whoami().profile.nickname}/"
    command = "find \"#{path}\" -type f -iname \"*#{keyword}*\""

    @getSingleton('kiteController').run command, (err, res) =>
      @searchHelper keyword, @parseResponse res

  searchHelper: (keyword, files) ->
    return @fatihView.emit "PluginFoundNothing" if files.length is 0

    @emit "FatihPluginCreatedAList", files, FatihFileListItem

  parseResponse: (res) ->
    files     = []

    if res
      paths   = res.replace(/\/Users/g, "Users").split '\n'
      files.push { path } for path in paths when path and path.indexOf("Users") is 0

    return files