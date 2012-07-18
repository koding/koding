module.exports =
  name              : "databases"
  pidPath           : "/var/run/node/Databases.pid"
  logFile           : "/var/log/node/Databases.log"
  port              : 4568
  pusher            :
    appId           : 18240
    key             : 'a19c8bf6d2cad6c7a006'
    secret          : '51f7913fbb446767a9fb'
  apiUri            : 'https://api.koding.com/1.0'
  mysql   :
    usersPath : '/Users/'
    backupDir : '/Backups/mysql'
    databases :
      mysql   : [
        { host     : 'mysql0.db.koding.com', user : 'system', password : 'gTW9ts2A4PXyECd69MQNAKx8v988x27cxFAu73pv' }
        { host     : 'mysql1.db.koding.com', user : 'system', password : 'gTW9ts2A4PXyECd69MQNAKx8v988x27cxFAu73pv' }
      ]
  mongo :
    databases :
      mongodb   : [
        { host     : 'mongo1.db.koding.com', user : 'admin', password : '22t78skhdlksaje1'}
        { host     : 'mongo0.db.koding.com', user : 'admin', password : '22t78skhdlksaje1'}
      ]
