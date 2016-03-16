fs        = require 'fs'
faker     = require 'faker'
tempDir   = require 'os-tmpdir'
formatter = require 'json-format'


module.exports =

  generateUsers: ->

    users = []

    for [1..10]

      name     = faker.Name.findName()
      username = faker.Helpers.slugify(faker.Internet.userName()).toLowerCase().replace(/\./g, '').replace(/_/g, '')
      username = username.substring(0, 7) + Date.now()
      password = @getPassword()
      teamSlug = name.toLowerCase().replace(/\s/g, '-').replace(/'/g, '').replace('.', '')
      helpers  = require '../helpers/helpers'
      fakeText = helpers.getFakeText()

      email = "kodingtestuser+#{username}@koding.com"

      users.push { name, email, username, password, teamSlug, fakeText }

    fs.writeFileSync 'users.json', formatter users, 'utf-8'

    return users


  getPassword: ->

    password = faker.Helpers.slugify(faker.Internet.userName())

    while password.length < 12
      password = faker.Helpers.slugify(faker.Internet.userName())

    return password


  getUser: (createNewUserData, index = 0) ->

    if createNewUserData
      users = @generateUsers()
      return if index is -1 then users else users[index]

    try
      usersFile = fs.readFileSync('users.json')
      users = JSON.parse(usersFile)

      return if index is -1 then users else users[index]

    catch

      users = @generateUsers()
      return if index is -1 then users else users[index]


  getHookFilePath: (type) ->

    hookDir = process.env.TEST_SUITE_HOOK_DIR
    { TEST_GROUP, TEST_SUITE } = process.env

    return "#{hookDir}/#{TEST_GROUP}_#{TEST_SUITE}_#{type}"


  registerSuiteHook: (type) -> fs.writeFileSync @getHookFilePath(type), ''


  suiteHookHasRun: (type) ->
    try
      fs.statSync @getHookFilePath type
      return yes
    catch
      return no



  getCollabLinkFilePath: -> return "#{tempDir()}/collabLink.txt"


  beforeCollaborationSuite: (browser) ->

    @getUser()  if process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    @registerSuiteHook 'before'  unless @suiteHookHasRun 'before'


  afterEachCollaborationTest: (browser, done) -> browser.deleteCollabLink done
