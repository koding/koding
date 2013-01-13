#!/usr/bin/python2.4

"""MobWrite - Real-time Synchronization and Collaboration Service

Copyright 2008 Google Inc.
http://code.google.com/p/google-mobwrite/

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

"""This file is the server, running under Google App Engine.

Accepting synchronization sessions from clients.
"""

__author__ = "fraser@google.com (Neil Fraser)"

import cgi
import cPickle
import datetime
import os
import sys
import urllib

from google.appengine.ext import db
from google.appengine import runtime
from google.appengine.api import memcache

sys.path.insert(0, "lib")
import mobwrite_core
del sys.path[0]


class TextObj(mobwrite_core.TextObj, db.Model):
  # An object which stores a text.

  # Object properties:
  # .lasttime - The last time that this text was modified.

  # Inherited properties:
  # .name - The unique name for this text, e.g 'proposal'.
  # .text - The text itself.
  # .changed - Has the text changed since the last time it was saved.

  text = db.TextProperty()
  lasttime = db.DateTimeProperty(auto_now=True)

  def __init__(self, *args, **kwargs):
    # Setup this object
    mobwrite_core.TextObj.__init__(self, *args, **kwargs)
    db.Model.__init__(self, *args, **kwargs)

  def setText(self, newtext):
    mobwrite_core.TextObj.setText(self, newtext)

    if (not self.changed and
        self.lasttime + mobwrite_core.TIMEOUT_TEXT <
        datetime.datetime.now() + mobwrite_core.TIMEOUT_VIEW):
      # Text object will expire before its view.  Bump the database.
      self.changed = True
      mobwrite_core.LOG.info("Keep-alive save for TextObj: '%s'" % self)

    if self.changed:
      self.put()
      if newtext is None:
        mobwrite_core.LOG.debug("Nullified TextObj: '%s'" % self)
      else:
        mobwrite_core.LOG.debug("Saved %db TextObj: '%s'" % (len(newtext), self))
      self.changed = False

  def safe_name(unsafe_name):
    # DataStore doesn't like names starting with numbers.
    return "_" + unsafe_name
  safe_name = staticmethod(safe_name)

  def __str__(self):
    if self.is_saved():
      return str(self.key().id_or_name())
    return "[Unsaved TextObj%x]" % id(self)

def fetchText(name):
  filename = TextObj.safe_name(name)
  textobj = TextObj.get_or_insert(filename)
  if textobj.text is None:
    mobwrite_core.LOG.debug("Loaded null TextObj: '%s'" % filename)
  else:
    mobwrite_core.LOG.debug("Loaded %db TextObj: '%s'" %
        (len(textobj.text), filename))
  return textobj


class ViewObj(mobwrite_core.ViewObj, db.Model):
  # An object which contains one user's view of one text.

  # Object properties:
  # .edit_pickle - Pickled version of edit stack.
  # .lasttime - The last time that a web connection serviced this object.
  # .textobj - The shared text object being worked on.

  # Inherited properties:
  # .username - The name for the user, e.g 'fraser'
  # .filename - The name for the file, e.g 'proposal'
  # .shadow - The last version of the text sent to client.
  # .backup_shadow - The previous version of the text sent to client.
  # .shadow_client_version - The client's version for the shadow (n).
  # .shadow_server_version - The server's version for the shadow (m).
  # .backup_shadow_server_version - the server's version for the backup
  #     shadow (m).
  # .edit_stack - List of unacknowledged edits sent to the client.
  # .changed - Has the view changed since the last time it was saved.
  # .delta_ok - Did the previous delta match the text length.

  username = db.StringProperty(required=True)
  filename = db.StringProperty(required=True)
  shadow = db.TextProperty()
  backup_shadow = db.TextProperty()
  shadow_client_version = db.IntegerProperty(required=True)
  shadow_server_version = db.IntegerProperty(required=True)
  backup_shadow_server_version = db.IntegerProperty(required=True)
  edit_pickle = db.TextProperty()
  lasttime = db.DateTimeProperty(auto_now=True)
  textobj = db.ReferenceProperty(TextObj)

  def __init__(self, *args, **kwargs):
    # Setup this object
    mobwrite_core.ViewObj.__init__(self, *args, **kwargs)
    # The three version numbers are required when defining a db.Model
    kwargs["shadow_client_version"] = self.shadow_client_version
    kwargs["shadow_server_version"] = self.shadow_server_version
    kwargs["backup_shadow_server_version"] = self.backup_shadow_server_version
    db.Model.__init__(self, *args, **kwargs)

  def nullify(self):
    mobwrite_core.ViewObj.__init__(self, username=self.username,
                                         filename=self.filename)
    self.shadow = None
    self.changed = True
    mobwrite_core.LOG.debug("Nullified ViewObj: '%s'" % self)

  def __str__(self):
    if self.is_saved():
      return str(self.key().id_or_name())
    return "[Unsaved ViewObj%x]" % id(self)

  def getKey(username, filename):
    # DataStore doesn't like names starting with numbers.
    name = "_%s@%s" % (username, filename)
    return db.Key.from_path(ViewObj.kind(), name)
  getKey = staticmethod(getKey)

class AppEngineMobWrite(mobwrite_core.MobWrite):

  def feedBuffer(self, name, size, index, datum):
    """Add one block of text to the buffer and return the whole text if the
      buffer is complete.

    Args:
      name: Unique name of buffer object.
      size: Total number of slots in the buffer.
      index: Which slot to insert this text (note that index is 1-based)
      datum: The text to insert.

    Returns:
      String with all the text blocks merged in the correct order.  Or if the
      buffer is not yet complete returns the empty string.
    """
    text = ""
    if not 0 < index <= size:
      mobwrite_core.LOG.error("Invalid buffer: '%s %d %d'" % (name, size, index))
    elif size == 1 and index == 1:
      # A buffer with one slot?  Pointless.
      text = datum
      mobwrite_core.LOG.debug("Buffer with only one slot: '%s'" % name)
    else:
      timeout = mobwrite_core.TIMEOUT_BUFFER.seconds
      mc = memcache.Client()
      namespace = "%s_%d" % (name, size)
      # Save this buffer to memcache.
      if mc.add(str(index), datum, time=timeout, namespace=namespace):
        # Add a counter or increment it if it already exists.
        counter = 1
        if not mc.add("counter", counter, time=timeout, namespace=namespace):
          counter = mc.incr("counter", namespace=namespace)
        if counter == size:
          # The buffer is complete.  Extract the data.
          keys = []
          for index in xrange(1, size + 1):
            keys.append(str(index))
          data_map = mc.get_multi(keys, namespace=namespace)
          data_array = []
          for index in xrange(1, size + 1):
            datum = data_map.get(str(index))
            if datum is None:
              mobwrite_core.LOG.critical("Memcache buffer '%s' does not contain element %d."
                  % (namespace, index))
              return ""
            data_array.append(datum)
          text = str("".join(data_array))
          # Abandon the data, memcache will clean it up.
      else:
        mobwrite_core.LOG.warning("Duplicate packet for buffer '%s'." % namespace)
    return urllib.unquote(text)

  def cleanup(self):
    def cleanTable(name, limit):
      query = db.GqlQuery("SELECT * FROM %s WHERE lasttime < :1" % name, limit)
      while 1:
        results = query.fetch(maxlimit)
        print "Deleting %d %s(s)." % (len(results), name)
        if results:
          db.delete(results)
        if len(results) != maxlimit:
          break

    mobwrite_core.LOG.info("Cleaning database")
    maxlimit = 50
    try:
      # Delete any view which hasn't been written to in a while.
      limit = datetime.datetime.now() - mobwrite_core.TIMEOUT_VIEW
      cleanTable("ViewObj", limit)

      # Delete any text which hasn't been written to in a while.
      limit = datetime.datetime.now() - mobwrite_core.TIMEOUT_TEXT
      cleanTable("TextObj", limit)

      print "Database clean."
      mobwrite_core.LOG.info("Database clean")
    except runtime.DeadlineExceededError:
      print "Cleanup only partially complete.  Deadline exceeded."
      mobwrite_core.LOG.warning("Database only partially cleaned. (DeadlineExceededError)")
    except db.Timeout:
      print "Cleanup only partially complete.  Database timeout."
      mobwrite_core.LOG.warning("Database only partially cleaned. (Timeout)")

  def handleRequest(self, text):
    actions = self.parseRequest(text)
    return self.doActions(actions)

  def loadViews(self, actions):
    # Enumerate all the requested view objects.
    # Build a list of database keys and ids for each object
    viewobj_keys = []
    viewobj_ids = []
    for action in actions:
      if (action["username"], action["filename"]) not in viewobj_ids:
        viewobj_ids.append((action["username"], action["filename"]))
        viewobj_keys.append(ViewObj.getKey(action["username"], action["filename"]))

    # Load all needed view objects from Datastore
    viewobj_values = db.get(viewobj_keys)

    # Populate the hashes and create any missing objects.
    viewobjs = {}
    for index in xrange(len(viewobj_ids)):
      id = viewobj_ids[index]
      viewobj = viewobj_values[index]
      if viewobj is None:
        viewobj = ViewObj(key_name=viewobj_keys[index].name(),
            username=action["username"], filename=action["filename"])
        mobwrite_core.LOG.debug("Created new ViewObj: '%s'" % viewobj)
      else:
        # Uncompress the edit stack from a string.
        viewobj.edit_stack = cPickle.loads(str(viewobj.edit_pickle))
        mobwrite_core.LOG.debug("Loaded %db ViewObj: '%s'" %
            (len(viewobj.shadow), viewobj))
      viewobjs[id] = viewobj
    return viewobjs

  def saveViews(self, viewobjs):
    # Build unified list of objects to save to Datastore.
    save = []
    delete = []

    for viewobj in viewobjs.values():
      if viewobj.shadow is None:
        mobwrite_core.LOG.debug("Nullified ViewObj: '%s'" % viewobj)
        if viewobj.is_saved():
          delete.append(viewobj)
      elif viewobj.changed:
        # Compress the edit stack into a string.
        viewobj.edit_pickle = cPickle.dumps(viewobj.edit_stack)
        mobwrite_core.LOG.debug("Saved %db ViewObj: '%s'" %
            (len(viewobj.shadow), viewobj))
        save.append(viewobj)
        viewobj.changed = False

    # Perform Datastore actions for multiple objects in a single command.
    if save:
      db.put(save)
    if delete:
      db.delete(delete)

  def doActions(self, actions):
    viewobjs = self.loadViews(actions)

    output = []
    viewobj = None
    last_username = None
    last_filename = None
    user_views = None

    for action_index in xrange(len(actions)):
      # Use an indexed loop in order to peek ahead on step to detect
      # username/filename boundaries.
      action = actions[action_index]
      username = action["username"]
      filename = action["filename"]
      viewobj = viewobjs[(username, filename)]
      viewobj.textobj = fetchText(filename)
      if action["mode"] == "null":
        # Nullify the text.
        mobwrite_core.LOG.debug("Nullifying: '%s'" % viewobj)
        # Textobj transaction not needed; just a set.
        textobj = viewobj.textobj
        textobj.setText(None)
        viewobj.nullify();
        continue

      if (action["server_version"] != viewobj.shadow_server_version and
          action["server_version"] == viewobj.backup_shadow_server_version):
        # Client did not receive the last response.  Roll back the shadow.
        mobwrite_core.LOG.warning("Rollback from shadow %d to backup shadow %d" %
            (viewobj.shadow_server_version, viewobj.backup_shadow_server_version))
        viewobj.shadow = viewobj.backup_shadow
        viewobj.shadow_server_version = viewobj.backup_shadow_server_version
        viewobj.edit_stack = []
        viewobj.changed = True

      # Remove any elements from the edit stack with low version numbers which
      # have been acked by the client.
      x = 0
      while x < len(viewobj.edit_stack):
        if viewobj.edit_stack[x][0] <= action["server_version"]:
          del viewobj.edit_stack[x]
        else:
          x += 1

      if action["mode"] == "raw":
        # It's a raw text dump.
        data = urllib.unquote(action["data"]).decode("utf-8")
        mobwrite_core.LOG.info("Got %db raw text: '%s'" % (len(data), viewobj))
        viewobj.delta_ok = True
        # First, update the client's shadow.
        viewobj.shadow = data
        viewobj.shadow_client_version = action["client_version"]
        viewobj.shadow_server_version = action["server_version"]
        viewobj.backup_shadow = viewobj.shadow
        viewobj.backup_shadow_server_version = viewobj.shadow_server_version
        viewobj.edit_stack = []
        viewobj.changed = True
        # Textobj transaction not needed; in a collision here data-loss is
        # inevitable anyway.
        textobj = viewobj.textobj
        if action["force"] or textobj.text is None:
          # Clobber the server's text.
          if textobj.text != data:
            textobj.setText(data)
            mobwrite_core.LOG.debug("Overwrote content: '%s'" % viewobj)
      elif action["mode"] == "delta":
        # It's a delta.
        mobwrite_core.LOG.info("Got '%s' delta: '%s'" % (action["data"], viewobj))
        if action["server_version"] != viewobj.shadow_server_version:
          # Can't apply a delta on a mismatched shadow version.
          viewobj.delta_ok = False
          mobwrite_core.LOG.warning("Shadow version mismatch: %d != %d" %
              (action["server_version"], viewobj.shadow_server_version))
        elif action["client_version"] > viewobj.shadow_client_version:
          # Client has a version in the future?
          viewobj.delta_ok = False
          mobwrite_core.LOG.warning("Future delta: %d > %d" %
              (action["client_version"], viewobj.shadow_client_version))
        elif action["client_version"] < viewobj.shadow_client_version:
          # We've already seen this diff.
          pass
          mobwrite_core.LOG.warning("Repeated delta: %d < %d" %
              (action["client_version"], viewobj.shadow_client_version))
        else:
          # Expand the delta into a diff using the client shadow.
          if viewobj.shadow is None:
            # This view was previously nullified.
            viewobj.shadow = ""
          try:
            diffs = mobwrite_core.DMP.diff_fromDelta(viewobj.shadow, action["data"])
          except ValueError:
            diffs = None
            viewobj.delta_ok = False
            mobwrite_core.LOG.warning("Delta failure, expected %d length: '%s'" %
                                      (len(viewobj.shadow), viewobj))
          viewobj.shadow_client_version += 1
          viewobj.changed = True
          if diffs != None:
            # Textobj transaction required for read/patch/write cycle.
            db.run_in_transaction(self.applyPatches, viewobj, diffs,
                action)

      # Generate output if this is the last action or the username/filename
      # will change in the next iteration.
      if ((action_index + 1 == len(actions)) or
          actions[action_index + 1]["username"] != username or
          actions[action_index + 1]["filename"] != filename):
        print_username = None
        print_filename = None
        if action["echo_username"] and last_username != username:
          # Print the username if the previous action was for a different user.
          print_username = username
        if last_filename != filename or last_username != username:
          # Print the filename if the previous action was for a different user
          # or file.
          print_filename = filename
        output.append(self.generateDiffs(viewobj, print_username,
                                         print_filename, action["force"]))
        last_username = username
        last_filename = filename

    self.saveViews(viewobjs)
    return "".join(output)


  def generateDiffs(self, viewobj, print_username, print_filename, force):
    output = []
    if print_username:
      output.append("u:%s\n" %  print_username)
    if print_filename:
      output.append("F:%d:%s\n" % (viewobj.shadow_client_version, print_filename))

    # Textobj transaction not needed; just a get, stale info is ok.
    textobj = viewobj.textobj
    mastertext = textobj.text

    if viewobj.delta_ok:
      if mastertext is None:
        mastertext = ""
      # Create the diff between the view's text and the master text.
      diffs = mobwrite_core.DMP.diff_main(viewobj.shadow, mastertext)
      mobwrite_core.DMP.diff_cleanupEfficiency(diffs)
      text = mobwrite_core.DMP.diff_toDelta(diffs)
      if force:
        # Client sending 'D' means number, no error.
        # Client sending 'R' means number, client error.
        # Both cases involve numbers, so send back an overwrite delta.
        viewobj.edit_stack.append((viewobj.shadow_server_version,
            "D:%d:%s\n" % (viewobj.shadow_server_version, text)))
      else:
        # Client sending 'd' means text, no error.
        # Client sending 'r' means text, client error.
        # Both cases involve text, so send back a merge delta.
        viewobj.edit_stack.append((viewobj.shadow_server_version,
            "d:%d:%s\n" % (viewobj.shadow_server_version, text)))
      viewobj.shadow_server_version += 1
      mobwrite_core.LOG.info("Sent '%s' delta: '%s'" % (text, viewobj))
    else:
      # Error; server could not parse client's delta.
      # Send a raw dump of the text.
      viewobj.shadow_client_version += 1
      if mastertext is None:
        mastertext = ""
        viewobj.edit_stack.append((viewobj.shadow_server_version,
            "r:%d:\n" % viewobj.shadow_server_version))
        mobwrite_core.LOG.info("Sent empty raw text: '%s'" % viewobj)
      else:
        # Force overwrite of client.
        text = mastertext
        text = text.encode("utf-8")
        text = urllib.quote(text, "!~*'();/?:@&=+$,# ")
        viewobj.edit_stack.append((viewobj.shadow_server_version,
            "R:%d:%s\n" % (viewobj.shadow_server_version, text)))
        mobwrite_core.LOG.info("Sent %db raw text: '%s'" %
            (len(text), viewobj))

    viewobj.shadow = mastertext
    viewobj.changed = True

    for edit in viewobj.edit_stack:
      output.append(edit[1])

    return "".join(output)


def main():
  mobwrite_core.CFG.initConfig("lib/mobwrite_config.txt")
  mobwrite = AppEngineMobWrite()
  form = cgi.FieldStorage()
  if form.has_key("q"):
    # Client sending a sync.  Requesting text return.
    print "Content-Type: text/plain"
    print ""
    print mobwrite.handleRequest(form["q"].value)
  elif form.has_key("p"):
    # Client sending a sync.  Requesting JS return.
    print "Content-Type: text/javascript"
    print ""
    value = mobwrite.handleRequest(form["p"].value)
    value = value.replace("\\", "\\\\").replace("\"", "\\\"")
    value = value.replace("\n", "\\n").replace("\r", "\\r")
    print "mobwrite.callback(\"%s\");" % value
  elif form.has_key("clean"):
    # Cron job to clean the database.
    print "Content-Type: text/plain"
    print ""
    mobwrite.cleanup()
  elif os.environ["QUERY_STRING"]:
    # Display a minimal editor.
    print "Content-Type: text/html"
    print ""
    f = open("default_editor.html")
    print f.read()
    f.close
  else:
    # Unknown request.
    print "Content-Type: text/plain"
    print ""

  mobwrite_core.LOG.debug("Disconnecting.")


if __name__ == "__main__":
  mobwrite_core.logging.basicConfig()
  main()
  mobwrite_core.logging.shutdown()
