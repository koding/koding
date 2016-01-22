fs        = require 'fs'
faker     = require 'faker'
formatter = require 'json-format'

module.exports =

  generateUsers: ->

    users = []

    for i in [1..10]

      name     = faker.Name.findName()
      username = faker.Helpers.slugify(faker.Internet.userName()).toLowerCase().replace(/\./g, '').replace(/_/g, '')
      username = username.substring(0, 7) + Date.now()
      password = @getPassword()
      teamSlug = name.toLowerCase().replace(/\s/g, '-').replace(/'/g, '').replace('.', '')

      email = "kodingtestuser+#{username}@koding.com"

      users.push { name, email, username, password, teamSlug }

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
