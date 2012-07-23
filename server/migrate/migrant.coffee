class Migrant
  
  mongoose = require 'node_modules/mongoose'
  
  {
    @Connection
    @Collection
    @Schema
    Types: {
      @ObjectId
    }
    Schema: {
      @Mixed
    }
    @connnection
  } = mongoose
  
  migrate:->
    @constructor.migrate @
  
  @migrate:->
    throw new Error 'This is an abstract interface.  Instantiate a subclass!'