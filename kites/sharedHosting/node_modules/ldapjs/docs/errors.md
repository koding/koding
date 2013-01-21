---
title: Errors API | ldapjs
markdown2extras: wiki-tables
logo-color: green
logo-font-family: google:Aldrich, Verdana, sans-serif
header-font-family: google:Aldrich, Verdana, sans-serif
---

# ldapjs Errors API

This document covers the ldapjs errors API and assumes that you are familiar
with LDAP. If you're not, read the [guide](http://ldapjs.org/guide.html) first.

All errors in the ldapjs framework extend from an abstract error type called
`LDAPError`. In addition to the properties listed below, all errors will have
a `stack` property correctly set.

In general, you'll be using the errors in ldapjs like:

    var ldap = require('ldapjs');

    var db = {};

    server.add('o=example', function(req, res, next) {
      var parent = req.dn.parent();
      if (parent) {
        if (!db[parent.toString()])
          return next(new ldap.NoSuchObjectError(parent.toString()));
      }
      if (db[req.dn.toString()])
        return next(new ldap.EntryAlreadyExistsError(req.dn.toString()));

      ...
    });

I.e., if you just pass them into the `next()` handler, ldapjs will automatically
return the appropriate LDAP error message, and stop the handler chain.

All errors will have the following properties:

## code

Returns the LDAP status code associated with this error.

## name

The name of this error.

## message

The message that will be returned to the client.

# Complete list of LDAPError subclasses

* OperationsError
* ProtocolError
* TimeLimitExceededError
* SizeLimitExceededError
* CompareFalseError
* CompareTrueError
* AuthMethodNotSupportedError
* StrongAuthRequiredError
* ReferralError
* AdminLimitExceededError
* UnavailableCriticalExtensionError
* ConfidentialityRequiredError
* SaslBindInProgressError
* NoSuchAttributeError
* UndefinedAttributeTypeError
* InappropriateMatchingError
* ConstraintViolationError
* AttributeOrValueExistsError
* InvalidAttriubteSyntaxError
* NoSuchObjectError
* AliasProblemError
* InvalidDnSyntaxError
* AliasDerefProblemError
* InappropriateAuthenticationError
* InvalidCredentialsError
* InsufficientAccessRightsError
* BusyError
* UnavailableError
* UnwillingToPerformError
* LoopDetectError
* NamingViolationError
* ObjectclassViolationError
* NotAllowedOnNonLeafError
* NotAllowedOnRdnError
* EntryAlreadyExistsError
* ObjectclassModsProhibitedError
* AffectsMultipleDsasError
* OtherError
