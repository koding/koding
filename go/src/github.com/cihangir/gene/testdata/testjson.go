// Package testdata provides test data to the other packages
package testdata

//  JSON1 holds a primitive json
const JSON1 = `
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "additionalProperties": true,
  "title": "Account",
  "description": "Account module handles all the operations regarding Account management.",
  "properties": {},
  "definitions": {
    "Config": {
      "type": "config",
      "additionalProperties": true,
      "title": "Config",
      "description": "Config represents the required options for this module to work",
      "properties": {
        "Postgres": {
          "type": "object",
          "additionalProperties": true,
          "title": "Postgres",
          "description": "Postgres holds the all credentials for postgres db connection.",
          "properties": {
            "Port": {
              "description": "The port number for postgres config",
              "type": "number",
              "format": "int64",
              "minimum": 1024
            },
            "Host": {
              "description": "Host holds the hostname for the postgres",
              "type": "string",
              "minLength": 4,
              "maxLength": 24
            },
            "Username": {
              "description": "Username holds the username for the postgres",
              "type": "string",
              "minLength": 4,
              "maxLength": 24
            },
            "Password": {
              "description": "Password holds the password for the postgres",
              "type": "string",
              "minLength": 4,
              "maxLength": 24
            },
            "DBName": {
              "description": "DBName holds the database name for the postgres",
              "type": "string",
              "minLength": 4,
              "maxLength": 24
            }
          },
          "definitions": {}
        },
        "Mongo": {
          "type": "object",
          "additionalProperties": true,
          "title": "Mongo",
          "description": "Mongo holds the all credentials for Mongo db connection.",
          "properties": {
            "Port": {
              "description": "The port number for Mongo config",
              "type": "number",
              "format": "int64",
              "minimum": 1024
            },
            "Host": {
              "description": "Host holds the hostname for the Mongo",
              "type": "string",
              "minLength": 4,
              "maxLength": 24
            },
            "Username": {
              "description": "Username holds the username for the Mongo",
              "type": "string",
              "minLength": 4,
              "maxLength": 24
            },
            "Password": {
              "description": "Password holds the password for the Mongo",
              "type": "string",
              "minLength": 4,
              "maxLength": 24
            },
            "DBName": {
              "description": "DBName holds the database name for the Mongo",
              "type": "string",
              "minLength": 4,
              "maxLength": 24
            }
          },
          "definitions": {}
        }
      }
    },
    "Profile": {
      "type": "object",
      "title": "Profile",
      "description": "Profile represents a registered Account's Public Info",
      "generators": [
          {
              "ddl": {
                  "roleName": "social",
                  "grants": [ "SELECT", "INSERT", "UPDATE" ]
              }
          }
      ],
      "properties": {
        "Id": {
          "description": "The unique identifier for a Account's Profile",
          "type": "number",
          "format": "int64",
          "minimum": 1
        },
        "Nick": {
          "description": "Nick is the unique name for the Accounts",
          "type": "string",
          "minLength": 4,
          "maxLength": 24
        },
        "FirstName": {
          "description": "First Name of the Account",
          "type": "string",
          "minLength": 0,
          "maxLength": 255
        },
        "LastName": {
          "description": "Last Name of the Account",
          "type": "string",
          "minLength": 0,
          "maxLength": 255
        },
        "AvatarURL": {
          "description": "URL of the Account's Avatar",
          "type": "string"
        },
        "CreatedAt": {
          "description": "Profile's creation time",
          "type": "string",
          "format": "date-time",
          "default": "now()"
        }
      },
      "functions": {
        "One": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Profile"
            },
            "outgoing": {
              "$ref": "#/definitions/Profile"
            }
          }
        },
        "Create": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Profile"
            },
            "outgoing": {
              "$ref": "#/definitions/Profile"
            }
          }
        },
        "Update": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Profile"
            },
            "outgoing": {
              "$ref": "#/definitions/Profile"
            }
          }
        },
        "Delete": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Profile"
            },
            "outgoing": {
              "$ref": "#/definitions/Profile"
            }
          }
        },
        "Some": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Profile"
            },
            "outgoing": {
              "type": "array",
              "items": [
                {
                  "$ref": "#/definitions/Profile"
                }
              ]
            }
          }
        }
      },
      "required": [
        "Nick"
      ]
    },
    "Account": {
      "type": "object",
      "additionalProperties": true,
      "title": "Account",
      "description": "Account represents a registered User",
      "properties": {
        "Id": {
          "description": "The unique identifier for a Account's Profile",
          "type": "number",
          "format": "int64",
          "minimum": 1
        },
        "ProfileId": {
          "description": "The unique identifier for a Account's Profile",
          "type": "number",
          "format": "int64",
          "minimum": 1
        },
        "Password": {
          "description": "Salted Password of the Account",
          "type": "string",
          "minLength": 6
        },
        "URLName": {
          "description": "Salted Password of the Account",
          "type": "string",
          "minLength": 6
        },
        "URL": {
          "description": "Salted Password of the Account",
          "type": "string",
          "minLength": 6
        },
        "PasswordStatusConstant": {
          "description": "Status of the Account's Password",
          "type": "string",
          "enum": [
            "valid",
            "needsReset",
            "generated"
          ],
          "default": "valid"
        },
        "Salt": {
          "description": "Salt used to hash Password of the Account",
          "type": "string",
          "minLength": 0,
          "maxLength": 255
        },
        "EmailAddress": {
          "description": "Email Address of the Account",
          "type": "string",
          "format": "email"
        },
        "EmailStatusConstant": {
          "description": "Status of the Account's Email",
          "type": "string",
          "enum": [
            "verified",
            "notVerified"
          ],
          "default": "notVerified"
        },
        "StatusConstant": {
          "description": "Status of the Account",
          "type": "string",
          "enum": [
            "registered",
            "unregistered",
            "needsManualVerification"
          ],
          "default": "registered"
        },
        "CreatedAt": {
          "description": "Profile's creation time",
          "type": "string",
          "format": "date-time",
          "default": "now()"
        }
      },
      "functions": {
        "One": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Account"
            },
            "outgoing": {
              "$ref": "#/definitions/Account"
            }
          }
        },
        "Create": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Account"
            },
            "outgoing": {
              "$ref": "#/definitions/Account"
            }
          }
        },
        "Update": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Account"
            },
            "outgoing": {
              "$ref": "#/definitions/Account"
            }
          }
        },
        "Delete": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Account"
            },
            "outgoing": {
              "$ref": "#/definitions/Account"
            }
          }
        },
        "Some": {
          "type": "object",
          "title": "One",
          "properties": {
            "incoming": {
              "$ref": "#/definitions/Account"
            },
            "outgoing": {
              "type": "array",
              "items": [
                {
                  "$ref": "#/definitions/Account"
                }
              ]
            }
          }
        }
      },
      "required": [
        "Password",
        "EmailAddress"
      ]
    }
  }
}

`

// JSONWithModule holds a json with module support
const JSONWithModule = `{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "id": "http://savas.io/account",
  "type": "object",
  "additionalProperties": true,
  "title": "Account",
  "description": "Account module handles all the operations regarding account management.",
  "properties": {},
  "definitions": {
    "Address": {
      "id": "http: //savas.io/account/address",
      "type": "object",
      "additionalProperties": true,
      "title": "Address",
      "description": "Address holds the address of an account.",
      "properties": {
        "Street": {
          "id": "http: //savas.io/account/address/street",
          "type": "string",
          "minLength": 0,
          "title": "Street",
          "description": "Street name holds the name of the street for an address.",
          "default": "2nd Street"
        },
        "City": {
          "id": "http: //savas.io/account/address/city",
          "type": "string",
          "minLength": 0,
          "title": "City",
          "description": "City holds the name of the city for the address.",
          "default": "Manisa"
        }
      }
    },
    "PhoneNumber": {
      "id": "http: //savas.io/account/address/phoneNumber",
      "type": "object",
      "minItems": 1,
      "uniqueItems": false,
      "title": "PhoneNumber",
      "description": "Phone number holds a general data for a phone number.",
      "properties": {
        "Location": {
          "id": "http: //savas.io/account/address/phoneNumber/location",
          "type": "string",
          "minLength": 0,
          "title": "Location",
          "description": "Location holds the location data for the phone number.",
          "name": "location",
          "default": "home"
        },
        "Code": {
          "id": "http: //savas.io/account/address/phoneNumber/code",
          "type": "integer",
          "multipleOf": 1,
          "maximum": 100,
          "minimum": 1,
          "exclusiveMaximum": false,
          "exclusiveMinimum": false,
          "title": "Code",
          "description": "Code holds the area code for the phone number",
          "default": 44
        }
      }
    }
  }
}`
