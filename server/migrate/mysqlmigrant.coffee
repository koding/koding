class MySqlMigrant extends Migrant
  
  _client = null
  
  @getKodingenMysqlClient = ->
    return _client if _client
    
    _client = client = new (require('node_modules/mysql').Client)

    client.host       = '10.32.0.228'
    client.user       = 'devrim'
    client.password   = 'RQdJkVmcU'
    
    client