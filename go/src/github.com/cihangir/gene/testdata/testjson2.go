package testdata

// TestDataFull provides a fully fledged test data.
var TestDataFull = `{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "type": "object",
    "additionalProperties": true,
    "title": "Account",
    "description": "Account module handles all the operations regarding Account management.",
    "generators": [
        {
            "ddl": {
                "roleName": "social",
                "grants": [
                    "SELECT",
                    "UPDATE"
                ],
                "databaseName": "mydatabase",
                "schemaName": "account"
            },
            "dockerfiles": {
                "CMDPath": "./bin/"
            }
        }
    ],
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
                        "grants": [
                            "SELECT",
                            "UPDATE"
                        ],
                        "primaryKey": [
                            "Id"
                        ],
                        "uniqueKeys": [
                            [
                                "Id"
                            ],
                            [
                                "BooleanBare",
                                "StringBare"
                            ]
                        ],
                        "foreignKeys": [
                            ["AccountId", "Account.Account.Id"]
                        ]
                    }
                }
            ],
            "properties": {
                "Id": {
                    "description": "The unique identifier for a Account's Profile",
                    "type": "number",
                    "format": "int64",
                    "minimum": 1,
                    "propertyOrder": 10
                },
                "BooleanBare": {
                    "description": "A Boolean with no properties",
                    "type": "Boolean",
                    "propertyOrder": 20
                },
                "BooleanWithMaxLength": {
                    "description": "A boolean variable with max length",
                    "type": "boolean",
                    "maxLength": 24,
                    "propertyOrder": 21
                },
                "BooleanWithMinLength": {
                    "description": "A boolean variable with min length",
                    "type": "boolean",
                    "minLength": 24,
                    "propertyOrder": 22
                },
                "BooleanWithDefault": {
                    "description": "A boolean variable with default value",
                    "type": "boolean",
                    "default": true,
                    "propertyOrder": 23
                },
                "StringBare": {
                    "description": "A string with no properties",
                    "type": "string",
                    "propertyOrder": 30
                },
                "StringWithDefault": {
                    "description": "A string with deafult value",
                    "type": "string",
                    "default": "thisismydefaultvalue",
                    "propertyOrder": 31
                },
                "StringWithMaxLength": {
                    "description": "A String variable with max length",
                    "type": "string",
                    "maxLength": 24,
                    "propertyOrder": 32
                },
                "StringWithMinLength": {
                    "description": "A String variable with min length",
                    "type": "string",
                    "minLength": 24,
                    "propertyOrder": 33
                },
                "StringWithMaxAndMinLength": {
                    "description": "A String variable with min and max length",
                    "type": "string",
                    "minLength": 4,
                    "maxLength": 24,
                    "propertyOrder": 34
                },
                "StringWithPattern": {
                    "description": "A String variable with min length",
                    "type": "string",
                    "pattern": "^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$",
                    "propertyOrder": 35
                },
                "StringDateFormatted": {
                    "description": "A String variable formatted as date time",
                    "type": "string",
                    "format": "date-time",
                    "propertyOrder": 36
                },
                "StringDateFormattedWithDefault": {
                    "description": "A String variable formatted as date time with default",
                    "type": "string",
                    "format": "date-time",
                    "default": "now()",
                    "propertyOrder": 37
                },
                "StringUUIDFormatted": {
                    "description": "A String variable formatted as UUID",
                    "type": "string",
                    "format": "UUID",
                    "propertyOrder": 38
                },
                "StringUUIDFormattedWithDefault": {
                    "description": "A String variable formatted as UUID",
                    "type": "string",
                    "format": "UUID",
                    "default": "uuid_generate_v1()",
                    "propertyOrder": 39
                },
                "NumberBare": {
                    "description": "A number with no properties",
                    "type": "number",
                    "propertyOrder": 40
                },
                "NumberWithMultipleOf": {
                    "description": "A number with multiple of property",
                    "type": "number",
                    "multipleOf": 2,
                    "propertyOrder": 41
                },
                "NumberWithMultipleOfFormattedAsFloat64": {
                    "description": "A float64 number with multiple of property",
                    "type": "number",
                    "format": "float64",
                    "multipleOf": 6.4,
                    "propertyOrder": 42
                },
                "NumberWithMultipleOfFormattedAsFloat32": {
                    "description": "A float32 number with multiple of property",
                    "type": "number",
                    "format": "float32",
                    "multipleOf": 3.2,
                    "propertyOrder": 43
                },
                "NumberWithMultipleOfFormattedAsInt64": {
                    "description": "An int64 number with multiple of property",
                    "type": "number",
                    "format": "int64",
                    "multipleOf": 64,
                    "propertyOrder": 44
                },
                "NumberWithMultipleOfFormattedAsUInt64": {
                    "description": "An uint64 number with multiple of property",
                    "type": "number",
                    "format": "uint64",
                    "multipleOf": 64,
                    "propertyOrder": 45
                },
                "NumberWithMultipleOfFormattedAsInt32": {
                    "description": "An int32 number with multiple of property",
                    "type": "number",
                    "format": "int32",
                    "multipleOf": 2,
                    "propertyOrder": 46
                },
                "NumberWithMultipleOfFormattedAsUInt32": {
                    "description": "An uint32 number with multiple of property",
                    "type": "number",
                    "format": "uint32",
                    "multipleOf": 2
                },
                "NumberWithMultipleOfFormattedAsInt": {
                    "description": "An int number with multiple of property",
                    "type": "number",
                    "format": "int",
                    "multipleOf": 2
                },
                "NumberWithMultipleOfFormattedAsUInt": {
                    "description": "An uint number with multiple of property",
                    "type": "number",
                    "format": "uint",
                    "multipleOf": 2
                },
                "NumberWithMultipleOfFormattedAsInt16": {
                    "description": "An int16 number with multiple of property",
                    "type": "number",
                    "format": "int16",
                    "multipleOf": 2
                },
                "NumberWithMultipleOfFormattedAsUInt16": {
                    "description": "An uint16 number with multiple of property",
                    "type": "number",
                    "format": "uint16",
                    "multipleOf": 2
                },
                "NumberWithMultipleOfFormattedAsInt8": {
                    "description": "An int8 number with multiple of property",
                    "type": "number",
                    "format": "int8",
                    "multipleOf": 2
                },
                "NumberWithMultipleOfFormattedAsUInt8": {
                    "description": "An uint8 number with multiple of property",
                    "type": "number",
                    "format": "uint8",
                    "multipleOf": 2
                },
                "NumberWithMaximum": {
                    "description": "A number with maximum property",
                    "type": "number",
                    "maximum": 1023
                },
                "NumberWithMaximumAsFloat64": {
                    "description": "A float64 number with maximum property",
                    "type": "number",
                    "format": "float64",
                    "maximum": 6.4
                },
                "NumberWithMaximumAsFloat32": {
                    "description": "A float32 number with maximum property",
                    "type": "number",
                    "format": "float32",
                    "maximum": 3.2
                },
                "NumberWithMaximumAsInt64": {
                    "description": "An int64 number with maximum property",
                    "type": "number",
                    "format": "int64",
                    "maximum": 64
                },
                "NumberWithMaximumAsUInt64": {
                    "description": "An uint64 number with maximum property",
                    "type": "number",
                    "format": "uint64",
                    "maximum": 64
                },
                "NumberWithMaximumAsInt32": {
                    "description": "An int32 number with maximum property",
                    "type": "number",
                    "format": "int32",
                    "maximum": 2
                },
                "NumberWithMaximumAsUInt32": {
                    "description": "An uint32 number with maximum property",
                    "type": "number",
                    "format": "uint32",
                    "maximum": 2
                },
                "NumberWithMaximumAsInt": {
                    "description": "An int number with maximum property",
                    "type": "number",
                    "format": "int",
                    "maximum": 2
                },
                "NumberWithMaximumAsUInt": {
                    "description": "An uint number with maximum property",
                    "type": "number",
                    "format": "uint",
                    "maximum": 2
                },
                "NumberWithMaximumAsInt16": {
                    "description": "An int16 number with maximum property",
                    "type": "number",
                    "format": "int16",
                    "maximum": 2
                },
                "NumberWithMaximumAsUInt16": {
                    "description": "An uint16 number with maximum property",
                    "type": "number",
                    "format": "uint16",
                    "maximum": 2
                },
                "NumberWithMaximumAsInt8": {
                    "description": "An int8 number with maximum property",
                    "type": "number",
                    "format": "int8",
                    "maximum": 2
                },
                "NumberWithMaximumAsUInt8": {
                    "description": "An uint8 number with maximum property",
                    "type": "number",
                    "format": "uint8",
                    "maximum": 2
                },
                "NumberWithMinimumAsFloat64": {
                    "description": "A float64 number with minimum property",
                    "type": "number",
                    "format": "float64",
                    "minimum": 6.4
                },
                "NumberWithMinimumAsFloat32": {
                    "description": "A float32 number with minimum property",
                    "type": "number",
                    "format": "float32",
                    "minimum": 3.2
                },
                "NumberWithMinimumAsInt64": {
                    "description": "An int64 number with minimum property",
                    "type": "number",
                    "format": "int64",
                    "minimum": 64
                },
                "NumberWithMinimumAsUInt64": {
                    "description": "An uint64 number with minimum property",
                    "type": "number",
                    "format": "uint64",
                    "minimum": 64
                },
                "NumberWithMinimumAsInt32": {
                    "description": "An int32 number with minimum property",
                    "type": "number",
                    "format": "int32",
                    "minimum": 2
                },
                "NumberWithMinimumAsUInt32": {
                    "description": "An uint32 number with minimum property",
                    "type": "number",
                    "format": "uint32",
                    "minimum": 2
                },
                "NumberWithMinimumAsInt": {
                    "description": "An int number with minimum property",
                    "type": "number",
                    "format": "int",
                    "minimum": 2
                },
                "NumberWithMinimumAsUInt": {
                    "description": "An uint number with minimum property",
                    "type": "number",
                    "format": "uint",
                    "minimum": 2
                },
                "NumberWithMinimumAsInt16": {
                    "description": "An int16 number with minimum property",
                    "type": "number",
                    "format": "int16",
                    "minimum": 2
                },
                "NumberWithMinimumAsUInt16": {
                    "description": "An uint16 number with minimum property",
                    "type": "number",
                    "format": "uint16",
                    "minimum": 2
                },
                "NumberWithMinimumAsInt8": {
                    "description": "An int8 number with minimum property",
                    "type": "number",
                    "format": "int8",
                    "minimum": 2
                },
                "NumberWithMinimumAsUInt8": {
                    "description": "An uint8 number with minimum property",
                    "type": "number",
                    "format": "uint8",
                    "minimum": 2
                },
                "NumberWithExclusiveMaximumWithoutMaximum": {
                    "description": "A number with maximum property",
                    "type": "number",
                    "exclusiveMaximum": true
                },
                "NumberWithExclusiveMinimum": {
                    "description": "A number with minimum property",
                    "type": "number",
                    "minimum": 1023
                },
                "NumberWithExclusiveMinimumWithoutMinimum": {
                    "description": "A number with minimum property",
                    "type": "number",
                    "exclusiveMinimum": true
                },
                "EnumBare": {
                    "description": "A bare enum type",
                    "type": "string",
                    "enum": [
                        "enum1",
                        "enum2",
                        "enum3"
                    ]
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
