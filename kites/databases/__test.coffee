mySQL = require './mySQLApi'
mongoDB = require './mongodbApi'

optionsMysql =
  username    : 'dbtester'
  dbName      : Date.now()
  newPassword : 'ls;kls;ka;ska;sk'

mySQL.createDatabase optionsMysql,(error,result)->
  if error?
    console.error error
  else
    console.log result
    optionsMysql.dbUser = result.dbUser
    optionsMysql.dbName = result.dbName
    mySQL.changePassword optionsMysql,(error,result)->
      if error?
        console.error error
      else
        console.log result
        mySQL.removeDatabase optionsMysql,(error,result)->
          if error?
            console.error error
          else
            console.log result



optionsMongo =
  username : 'aleksey'
  dbName   : Date.now()
  newPassword : 'sklskalksla'


mongoDB.createDatabase optionsMongo,(error,result)->
  if error?
    console.error error
  else
    console.log result
    optionsMongo.dbUser = result.dbUser
    optionsMongo.dbName = result.dbName
    optionsMongo.dbPass = result.dbPass
    mongoDB.changePassword optionsMongo,(error,result)->
      if error?
        console.error error
      else
        console.log result
        optionsMongo.dbPass =  optionsMongo.newPassword
        mongoDB.removeDatabase optionsMongo,(error,result)->
          if error?
            console.error error
          else
            console.log result