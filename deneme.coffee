jraphical = require 'jraphical'
{Relationship} = jraphical


authenticator.setAccount 'siesta', ()->

  query = {
    sourceId: "52140ca08605ddee25000003"
    sourceName: 'JAccount'
    targetName: 'JReferral'
    as: 'referrer'
  }

  options = {
    limit: 10,
    targetOptions: {
      selector: { type: 'disk' }
    }
  }

  Relationship.some query, options, (err, acc)-> acc.fetchUser (er, user) -> console.log user
