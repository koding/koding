# Changelog

## Fri Nov 15 2013 - 0.2.0

- Fixed some struct field types
- Modified some of the tests
- Felt like it deserved a minor version bump

## Thu Nov 14 2013 - 0.1.9

- If verbosity is enabled, any unmarshaling errors will print the complete
  response body out, via logger

## Thu Nov 14 2013 - 0.1.8

## Wed Nov 13 2013 - 0.1.7

- Fixed a bug where empty request bodies would result in the API service
  responding with a 400 Bad Request
- Added some proper tests

## Wed Nov 13 2013 - 0.1.6

- Added a "verbose" mode to the client

## Tue Nov 12 2013 - 0.1.5

- Bug fixes
  - Logic bug in the *Client.Do() function, where it would not allow the
    POST /Session call if the client was logged out (POST /Session is used for
    logging in)

## Tue Nov 12 2013 - 0.1.4

- Includes 0.1.3
- Bug fixes
- Testing laid out, but there is not much there, as of right now

## Tue Nov 12 2013 - 0.1.2

- Bug fixes

## Tue Nov 12 2013 - 0.1.1

- Added structs for zone responses

## Tue Nov 12 2013 - 0.1.0

- Initial release
- The base client is complete; it will allow you to establish a session,
  terminate a session, and issue requests to the DynECT REST API endpoints
- TODO
  - Structs for marshaling and unmarshaling requests and responses still need
	to be done, as the current set of provided struct is all that is needed
	to be able to log in and create a session
  - More structs will be added on an "as I need them" basis
