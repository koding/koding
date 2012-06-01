// examples/mailform.cc
// This file is part of libpbe; see http://decimail.org
// (C) 2004 Philip Endecott

// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


// MAILFORM
// --------

// This is a demonstration of the libpbe CgiParams and SmtpClient
// classes.  It is a CGI program that implements the backend of a
// feedback form, or similar.  The user completes a form on a web page
// and submits it to this script, which forwards its content as an
// email message.

// The important bits of the form look like this:
// <form method="post" action="URL of this CGI program">
//   <input type="text" name="name">
//   <input type="text" name="email">
//   <textarea name="message"></textarea>
//   <input type="hidden" name="nextpage" value="feedback_received.html">
// </form>
//
// feedback_received.html is the page that will be shown when the
// message has been sucessfully sent.
//
// You can also note from which page the user clicked on the "feedback
// form" page using a tad of javascript (which will not mess up
// non-javascript browsers):
// <script language="javascript" type="text/javascript">
// <!--
// document.writeln('<input type="hidden" name="page" value="'+document.referrer+'">');
// // -->
// </script>
// (Put this inside the <form> element, obviously.)



// libpbe includes:

#include "CgiParams.hh"
#include "SmtpClient.hh"


// Standard includes:

#include <stdlib.h>

#include <iostream>
#include <string>
using namespace std;


// The values can be redefined using -D when compiling.  You at least
// need to supply sensible values for SENDER and RECIPIENT.

// From address if the user doesn't specify one:
#ifndef ANON_ADDR
  #define ANON_ADDR "anonymous"
#endif

// From address if the user doesn't specify one:
#ifndef SENDER
  #define SENDER "webpage@this_machine"
#endif

// Define the recipient of the emails here:
#ifndef RECIPIENT
  #define RECIPIENT "feedback@some_domain"
#endif

// SMTP server to connect to:
#ifndef SMTP_SERVER
  #define SMTP_SERVER "localhost"
#endif

// Our own domain name, as announced to the SMTP server when the
// connection is established:
#ifndef OWN_DOMAIN
  #define OWN_DOMAIN "localhost"
#endif


int main (int argc, char* argv[])
{
  // This must be called from a web server as a CGI program.  Give up
  // immediately if that doesn't seem to be the case.  (CGI sets
  // various environment variables, of which QUERY_STRING is one.)
  if (!getenv("QUERY_STRING")) {
    cerr << "This program must be invoked using CGI." << endl;
    exit(1);
  }
 
  // This is my standard idiom for top-level exception handling, see
  // below.
  try { try {

    // Create a CgiParams object and load it from the environment.  We
    // don't need to know the details of what this is doing, just that
    // it can cope with all of the variants of CGI encoding.
    CgiParams params;
    params.load();

    // Get the form values.  get_default() substitutes the supplied
    // default if no parameter with that name was supplied.  get()
    // throws an exception in this case.  operator[] can be used if
    // you are certain that the parameter is present (like a
    // std::map).
    string name =     params.get_default("name","(none)");
    string email =    params.get_default("email","(none)");
    string page =     params.get_default("page","(none)");
    string message =  params.get("message");
    string nextpage = params.get_default("nextpage","index.html");

    // Now construct the message.  This needs to be a complete message
    // in RFC822 (aka RFC2822 which is easier to read) format.

    // Do PLEASE ensure that your DATE is in the correct RFC822
    // format!  And, if you ever write code to parse an email, be
    // prepared for dates in just about any misformat you can imagine.
    // I speak from experience.
    char datetime[36];
    time_t t;
    time(&t);
    struct tm tm;
    localtime_r(&t,&tm);
    strftime(datetime,sizeof(datetime),"%a, %d %b %Y %H:%M:%S %z",&tm);

    // If the user gave an email address, we can give it here as the
    // from address.  That makes it easy to reply to the right place.
    // On the other hand it might break if you have a spam-filtering
    // system like SPF in place (anyone know the magic to avoid this?)
    string from_addr = (email=="" || email=="(none)") ? ANON_ADDR : email;

    string rfc822_message =
      "Sender: "  + string(SENDER)  + "\r\n"
      "From: "    + from_addr       + "\r\n"
      "To: "      + RECIPIENT       + "\r\n"
      "Subject: " + "Feedback form" + "\r\n"
      "Date: "    + datetime        + "\r\n"
      "\r\n"
      "Name:  " + name + "\r\n"
      "Email: " + email + "\r\n"
      "Page:  " + page  + "\r\n\r\n"
      "Message:\r\n" + message + "\r\n";

    // Now create the SMTP client.
    // If you want to see what is going on on the SMTP connection, you
    // can enable logging to syslog by defining SYSLOG in
    // SmtpClient.cc.
    SmtpClient smtpc;
    // Make an SMTP connection to the server
    smtpc.connect(SMTP_SERVER,OWN_DOMAIN);
    // Send the message
    smtpc.send_msg(SENDER,RECIPIENT,rfc822_message);
    // Done, disconnect.
    smtpc.disconnect();

    // Final thing to do is to redirect to the "message sent" HTML page.
    cout << "Location: " << nextpage << "\r\n\r\n";

    // All done.
    exit(0);


    // My standard exception handling magic.  This converts any odd
    // exception types, like char* from 'throw "something bad";', into
    // an Exception.
  } RETHROW_MISC_EXCEPTIONS }
  catch (Exception& E) {
    cout << "content-type: text/plain\r\n\r\n"
	 << "An error has occured:\r\n";
    E.report(cout);
    exit(0);
  }
}

