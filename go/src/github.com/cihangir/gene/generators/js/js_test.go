package js

import (
	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
)

func TestJSClient(t *testing.T) {
	t.Skip("js client is not complete yet")
	common.RunTest(t, &Generator{}, testdata.JSON1, expecteds)
}

var expecteds = []string{`module.exports.account = {
  // New creates a new local Account js client
  Account = function(){}

  // create validators
  Account.validate = function(data){
    return  null
  }

  // create mapper
  Account.map = function(data){
    return null
  }


  Account.Create = function(data, callback) {
    // data should be type of models.Account

    if(err = Account.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of models.Accountx
    res = Account.map(res)
    callback(null, res)
  }

  Account.Delete = function(data, callback) {
    // data should be type of models.Account

    if(err = Account.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of models.Accountx
    res = Account.map(res)
    callback(null, res)
  }

  Account.One = function(data, callback) {
    // data should be type of models.Account

    if(err = Account.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of models.Accountx
    res = Account.map(res)
    callback(null, res)
  }

  Account.Some = function(data, callback) {
    // data should be type of models.Account

    if(err = Account.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of []*models.Accountx
    res = res.map(function(datum) {
      return Account.map(datum);
    });
    callback(null, res)
  }

  Account.Update = function(data, callback) {
    // data should be type of models.Account

    if(err = Account.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of models.Accountx
    res = Account.map(res)
    callback(null, res)
  }

}
`,
	`module.exports.account = {
  // New creates a new local Profile js client
  Profile = function(){}

  // create validators
  Profile.validate = function(data){
    return  null
  }

  // create mapper
  Profile.map = function(data){
    return null
  }


  Profile.Create = function(data, callback) {
    // data should be type of models.Profile

    if(err = Profile.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of models.Profilex
    res = Profile.map(res)
    callback(null, res)
  }

  Profile.Delete = function(data, callback) {
    // data should be type of models.Profile

    if(err = Profile.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of models.Profilex
    res = Profile.map(res)
    callback(null, res)
  }

  Profile.One = function(data, callback) {
    // data should be type of models.Profile

    if(err = Profile.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of models.Profilex
    res = Profile.map(res)
    callback(null, res)
  }

  Profile.Some = function(data, callback) {
    // data should be type of models.Profile

    if(err = Profile.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of []*models.Profilex
    res = res.map(function(datum) {
      return Profile.map(datum);
    });
    callback(null, res)
  }

  Profile.Update = function(data, callback) {
    // data should be type of models.Profile

    if(err = Profile.validate(data)) {
      return callback(err, null)
    }


    // send request to the server
    // we got the response
    var res = {}
    // response should be type of models.Profilex
    res = Profile.map(res)
    callback(null, res)
  }

}
`,
}
