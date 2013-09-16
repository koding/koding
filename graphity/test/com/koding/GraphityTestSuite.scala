package com.koding

import org.scalatest.BeforeAndAfter
import org.scalatest.FunSuite

import com.google.gson.Gson
import com.sun.jersey.api.client.Client
import com.sun.jersey.api.client.ClientResponse
import com.sun.jersey.core.util.MultivaluedMapImpl

class GraphityTestSuite extends FunSuite with BeforeAndAfter {

  class Node {
    var self = ""
  }

  val gson = new Gson
  val client = Client.create
  val db = client.resource("http://localhost:7474/db/data/")
  val graphity = client.resource("http://localhost:7474/graphity/")

  var stream, source1, source2, event1, event2, event3: String = _

  before {
    stream = createNode("stream")
    source1 = createNode("source1")
    source2 = createNode("source2")
    event1 = createNode("event1")
    event2 = createNode("event2")
    event3 = createNode("event3")

    addSubscription(stream, source1)
    addSubscription(stream, source2)
  }

  test("adding events in order") {
    addEvent(source1, event1, 1)
    addEvent(source1, event2, 2)
    addEvent(source2, event3, 3)

    val list = getEvents(stream, 10)
    assert(list.size === 3)
    assert(list.get(0) === event3)
    assert(list.get(1) === event2)
    assert(list.get(2) === event1)
  }

  test("adding events in reverse order") {
    addEvent(source2, event3, 3)
    addEvent(source1, event2, 2)
    addEvent(source1, event1, 1)

    val list = getEvents(stream, 10)
    assert(list.size === 3)
    assert(list.get(0) === event3)
    assert(list.get(1) === event2)
    assert(list.get(2) === event1)
  }
  
  test("adding the same event multiple times") {
    addEvent(source1, event1, 1)
    addEvent(source1, event2, 2)
    addEvent(source1, event1, 1)

    val list = getEvents(stream, 10)
    assert(list.size === 2)
    assert(list.get(0) === event2)
    assert(list.get(1) === event1)
  }

  test("getting only a subset of events") {
    addEvent(source1, event1, 1)
    addEvent(source2, event2, 2)
    addEvent(source1, event3, 3)

    val list = getEvents(stream, 2)
    assert(list.size === 2)
    assert(list.get(0) === event3)
    assert(list.get(1) === event2)
  }

  test("getting only a timespan of events") {
    addEvent(source1, event1, 1)
    addEvent(source2, event2, 2)
    addEvent(source1, event3, 3)

    val json = graphity.path("events").queryParam("stream", stream).queryParam("count", "10").queryParam("before", "3").queryParam("after", "1").get(classOf[String])
    val list = gson.fromJson(json, classOf[java.util.List[String]])
    assert(list.size === 1)
    assert(list.get(0) === event2)
  }

  test("deleting events") {
    addEvent(source1, event1, 1)
    addEvent(source2, event2, 2)
    addEvent(source1, event3, 3)

    deleteEvent(event3)

    val list = getEvents(stream, 10)
    assert(list.size === 2)
    assert(list.get(0) === event2)
    assert(list.get(1) === event1)
  }

  test("deleting subscriptions") {
    addEvent(source1, event1, 1)
    addEvent(source2, event2, 2)
    addEvent(source1, event3, 3)

    deleteSubscription(stream, source1)

    val list = getEvents(stream, 10)
    assert(list.size === 1)
    assert(list.get(0) === event2)
  }

  test("getting subscriptions") {
    val list = getSubscriptions(stream)
    assert(list.size === 2)
    assert(list.get(0) === source1)
    assert(list.get(1) === source2)
  }

  def createNode(name: String) = {
    val json = db.path("node").accept("application/json").post(classOf[String])
    val node = gson.fromJson(json, classOf[Node])
    val parts = node.self.split("/")
    val shortUrl = "/" + parts(parts.size - 2) + "/" + parts(parts.size - 1)
    println(name + ": " + shortUrl)
    shortUrl
  }

  def addSubscription(stream: String, source: String) {
    val map = new MultivaluedMapImpl();
    map.add("stream", stream)
    map.add("source", source)
    graphity.path("subscriptions").post(classOf[ClientResponse], map)
  }

  def deleteSubscription(stream: String, source: String) {
    graphity.path("subscriptions").queryParam("stream", stream).queryParam("source", source).delete
  }

  def getSubscriptions(stream: String) = {
    val json = graphity.path("subscriptions").queryParam("stream", stream).get(classOf[String])
    gson.fromJson(json, classOf[java.util.List[String]])
  }

  def addEvent(source: String, event: String, timestamp: Long) {
    val map = new MultivaluedMapImpl();
    map.add("source", source)
    map.add("event", event)
    map.add("timestamp", timestamp)
    graphity.path("events").post(classOf[ClientResponse], map)
  }

  def deleteEvent(event: String) {
    graphity.path("events").queryParam("event", event).delete
  }

  def getEvents(stream: String, count: Int) = {
    val json = graphity.path("events").queryParam("stream", stream).queryParam("count", count.toString).get(classOf[String])
    gson.fromJson(json, classOf[java.util.List[String]])
  }

}