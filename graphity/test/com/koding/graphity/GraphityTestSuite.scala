package com.koding.graphity

import org.scalatest.FunSuite
import com.sun.jersey.api.client.Client
import com.sun.jersey.core.util.MultivaluedMapImpl
import com.google.gson.Gson

class GraphityTestSuite extends FunSuite {

  class Node {
    var self = ""
  }

  val gson = new Gson()
  val client = Client.create()
  val db = client.resource("http://localhost:7474/db/data/")
  val graphity = client.resource("http://localhost:7474/graphity/")

  test("inserting and retrieving events in correct order") {
    val stream = createNode("stream")
    val source1 = createNode("source1")
    val source2 = createNode("source2")
    val event1 = createNode("event1")
    val event2 = createNode("event2")
    val event3 = createNode("event3")

    addSubscription(stream, source1)
    addSubscription(stream, source2)

    addEvent(source1, event2, 2)
    addEvent(source2, event3, 3)
    addEvent(source1, event1, 1)

    val list1 = getEvents(stream, 2)
    assert(list1.size() === 2)
    assert(list1.get(0) === event3)
    assert(list1.get(1) === event2)

    val list2 = getEvents(stream, 10)
    assert(list2.size() === 3)
    assert(list2.get(0) === event3)
    assert(list2.get(1) === event2)
    assert(list2.get(2) === event1)
  }

  def createNode(name: String) = {
    val json = db.path("node").accept("application/json").post(classOf[String])
    val node = gson.fromJson(json, classOf[Node])
    println(name + ": " + node.self)
    node.self
  }

  def addSubscription(stream: String, source: String) {
    graphity.path("subscriptions").queryParam("stream", stream).queryParam("source", source).post()
  }

  def addEvent(source: String, event: String, timestamp: Long) {
    graphity.path("events").queryParam("source", source).queryParam("event", event).queryParam("timestamp", timestamp.toString()).post()
  }

  def getEvents(stream: String, count: Int) = {
    val json = graphity.path("events").queryParam("stream", stream).queryParam("count", count.toString()).get(classOf[String])
    gson.fromJson(json, classOf[java.util.List[String]])
  }

}