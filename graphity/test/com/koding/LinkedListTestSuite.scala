package com.koding

import org.scalatest.BeforeAndAfter
import org.scalatest.FunSuite
import com.sun.jersey.api.client.Client
import com.google.gson.Gson
import com.sun.jersey.core.util.MultivaluedMapImpl
import com.sun.jersey.api.client.ClientResponse

class LinkedListTestSuite extends FunSuite with BeforeAndAfter {

  class Node {
    var self = ""
  }

  val gson = new Gson
  val client = Client.create
  val db = client.resource("http://localhost:7474/db/data/")
  val linkedlist = client.resource("http://localhost:7474/linkedlist/")

  var head, tail: String = _

  before {
    head = createNode("head")
    tail = createNode("tail")
    createList(head, tail)
  }

  test("creating a list") {
    assert(getPrevious(tail) === head)
  }

  test("adding entries") {
    val entry1 = createNode("entry1")
    val entry2 = createNode("entry2")
    val entry3 = createNode("entry3")
    val entry4 = createNode("entry4")
    val entry5 = createNode("entry5")

    addEntryAfter(head, entry2)
    addEntryAfter(entry2, entry4)
    addEntryAfter(head, entry1)
    addEntryBefore(entry4, entry3)
    addEntryBefore(tail, entry5)

    assert(getPrevious(entry1) === head)
    assert(getPrevious(entry2) === entry1)
    assert(getPrevious(entry3) === entry2)
    assert(getPrevious(entry4) === entry3)
    assert(getPrevious(entry5) === entry4)
    assert(getPrevious(tail) === entry5)
  }

  test("get full list") {
    val entry1 = createNode("entry1")
    val entry2 = createNode("entry2")

    addEntryBefore(tail, entry1)
    addEntryBefore(tail, entry2)

    val list1 = getAll(head)
    assert(list1.size === 2)
    assert(list1.get(0) === entry1)
    assert(list1.get(1) === entry2)

    val list2 = getAll(tail)
    assert(list2.size === 2)
    assert(list2.get(0) === entry1)
    assert(list2.get(1) === entry2)

    val list3 = getAll(entry1)
    assert(list3.size === 2)
    assert(list3.get(0) === entry1)
    assert(list3.get(1) === entry2)
  }

  test("inserting at head and tail") {
    val entry1 = createNode("entry1")
    val entry2 = createNode("entry2")
    val entry3 = createNode("entry3")

    addEntryAfter(tail + ":head", entry2)
    addEntryBefore(entry2 + ":tail", entry3)
    addEntryAfter(entry2 + ":head", entry1)

    assert(getPrevious(entry1) === head)
    assert(getPrevious(entry2) === entry1)
    assert(getPrevious(entry3) === entry2)
    assert(getPrevious(tail) === entry3)
  }

  test("initializing a list multiple times") {
    createList(head, tail)
    createList(head, tail)

    val entry1 = createNode("entry1")
    addEntryBefore(tail, entry1)

    assert(getPrevious(entry1) === head)
    assert(getPrevious(tail) === entry1)
  }

  test("inserting an entry twice fails") {
    val entry1 = createNode("entry1")
    addEntryBefore(tail, entry1)
    intercept[IllegalArgumentException] {
      addEntryBefore(tail, entry1)
    }
  }

  test("deleting an entry") {
    val entry1 = createNode("entry1")
    val entry2 = createNode("entry2")
    val entry3 = createNode("entry3")

    addEntryBefore(tail, entry1)
    addEntryBefore(tail, entry2)
    addEntryBefore(tail, entry3)
    deleteEntry(entry2)

    assert(getPrevious(entry1) === head)
    assert(getPrevious(entry3) === entry1)
    assert(getPrevious(tail) === entry3)
  }

  test("deleting and recreating a list") {
    val entry1 = createNode("entry1")

    addEntryBefore(tail, entry1)
    deleteList(entry1)
    createList(head, tail)
    addEntryBefore(tail, entry1)

    assert(getPrevious(entry1) === head)
    assert(getPrevious(tail) === entry1)
  }

//  test("concurrent inserts") {
//    var threads: List[Thread] = Nil
//    1 to 1000 foreach { _ =>
//      val entry = createNode(null)
//      val t = new Thread(new Runnable {
//        def run() {
//          val client = Client.create
//          val db = client.resource("http://localhost:7474/db/data/")
//          val linkedlist = client.resource("http://localhost:7474/linkedlist/")
//
//          val map = new MultivaluedMapImpl()
//          map.add("next", tail)
//          map.add("entry", entry)
//          if (linkedlist.path("entry").post(classOf[ClientResponse], map).getClientResponseStatus() != ClientResponse.Status.NO_CONTENT) {
//            throw new IllegalArgumentException
//          }
//        }
//      })
//      threads ::= t
//    }
//    threads.foreach(t => t.start())
//    threads.foreach(t => t.join())
//  }

  def createNode(name: String) = {
    val json = db.path("node").accept("application/json").post(classOf[String])
    val node = gson.fromJson(json, classOf[Node])
    val parts = node.self.split("/")
    val shortUrl = "/" + parts(parts.size - 2) + "/" + parts(parts.size - 1)
    if (name != null) {
      println(name + ": " + shortUrl)
    }
    shortUrl
  }

  def createList(head: String, tail: String) {
    val map = new MultivaluedMapImpl()
    map.add("head", head)
    map.add("tail", tail)
    linkedlist.path("list").post(classOf[ClientResponse], map)
  }

  def deleteList(entry: String) {
    linkedlist.path("list").queryParam("entry", entry).delete
  }

  def addEntryAfter(previous: String, entry: String) {
    val map = new MultivaluedMapImpl()
    map.add("previous", previous)
    map.add("entry", entry)
    if (linkedlist.path("entry").post(classOf[ClientResponse], map).getClientResponseStatus() != ClientResponse.Status.NO_CONTENT) {
      throw new IllegalArgumentException
    }
  }

  def addEntryBefore(next: String, entry: String) {
    val map = new MultivaluedMapImpl()
    map.add("next", next)
    map.add("entry", entry)
    if (linkedlist.path("entry").post(classOf[ClientResponse], map).getClientResponseStatus() != ClientResponse.Status.NO_CONTENT) {
      throw new IllegalArgumentException
    }
  }

  def deleteEntry(entry: String) {
    linkedlist.path("entry").queryParam("entry", entry).delete
  }

  def getPrevious(entry: String) = {
    linkedlist.path("entry/previous").queryParam("entry", entry).get(classOf[String])
  }

  def getAll(entry: String) = {
    val json = linkedlist.path("entry/all").queryParam("entry", entry).get(classOf[String])
    gson.fromJson(json, classOf[java.util.List[String]])
  }

}