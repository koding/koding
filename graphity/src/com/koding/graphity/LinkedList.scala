package com.koding.graphity

import org.neo4j.graphdb.Direction
import org.neo4j.graphdb.Node
import org.neo4j.graphdb.RelationshipType

// Linked list with fixed head and tail nodes.
object LinkedList {

  // Points from head node and each entry node to tail node.
  object LINKED_LIST_TAIL extends RelationshipType { def name(): String = "LINKED_LIST_TAIL" }

  // Points from head or entry node to next entry node or tail node.
  object LINKED_LIST_NEXT extends RelationshipType { def name(): String = "LINKED_LIST_NEXT" }

  // Initializes a linked list with given head and tail nodes.
  def init(head: Node, tail: Node) {
    head.createRelationshipTo(tail, LINKED_LIST_TAIL)
    head.createRelationshipTo(tail, LINKED_LIST_NEXT)
  }

  // Searches backwards from tail until positionFilter returns true and inserts entry at that position.
  // The positionFilter must always return true for head node.
  def insertFromTail(tail: Node, positionFilter: (Node) => Boolean, entry: Node): Unit = {
    entry.createRelationshipTo(tail, LINKED_LIST_TAIL)

    var current = tail
    while (true) {
      val incomingNextRel = current.getSingleRelationship(LINKED_LIST_NEXT, Direction.INCOMING)
      val previous = incomingNextRel.getStartNode()

      if (positionFilter(previous)) {
        incomingNextRel.delete()
        previous.createRelationshipTo(entry, LINKED_LIST_NEXT)
        entry.createRelationshipTo(current, LINKED_LIST_NEXT)
        return
      }

      current = previous
    }
  }

  // Remove entry and return tail node. Do not execute on head or tail node.
  def remove(entry: Node) = {
    val tailRel = entry.getSingleRelationship(LINKED_LIST_TAIL, Direction.OUTGOING)
    val outgoingNextRel = entry.getSingleRelationship(LINKED_LIST_NEXT, Direction.OUTGOING)
    val incomingNextRel = entry.getSingleRelationship(LINKED_LIST_NEXT, Direction.INCOMING)

    tailRel.delete()
    outgoingNextRel.delete()
    incomingNextRel.delete()
    incomingNextRel.getStartNode().createRelationshipTo(outgoingNextRel.getEndNode(), LINKED_LIST_NEXT)

    tailRel.getEndNode()
  }

  // Get previous entry. Do not execute on head node.
  def getPrevious(entry: Node) = {
    entry.getSingleRelationship(LINKED_LIST_NEXT, Direction.INCOMING).getStartNode()
  }

}