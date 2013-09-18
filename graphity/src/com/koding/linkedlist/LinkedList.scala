package com.koding.linkedlist

import org.neo4j.graphdb.Direction
import org.neo4j.graphdb.Node
import org.neo4j.graphdb.RelationshipType

// Linked list with fixed head and tail nodes.
object LinkedList {

  // Points from tail node and each entry node to head node.
  object LINKED_LIST_HEAD extends RelationshipType { def name: String = "LINKED_LIST_HEAD" }

  // Points from head node and each entry node to tail node.
  object LINKED_LIST_TAIL extends RelationshipType { def name: String = "LINKED_LIST_TAIL" }

  // Points from head or entry node to next entry node or tail node.
  object LINKED_LIST_NEXT extends RelationshipType { def name: String = "LINKED_LIST_NEXT" }

  // Initializes a linked list with given head and tail nodes.
  def init(head: Node, tail: Node) {
    if (head.getSingleRelationship(LINKED_LIST_HEAD, Direction.OUTGOING) != null || tail.getSingleRelationship(LINKED_LIST_HEAD, Direction.OUTGOING) != null) {
      return
    }
    head.createRelationshipTo(head, LINKED_LIST_HEAD)
    head.createRelationshipTo(tail, LINKED_LIST_TAIL)
    tail.createRelationshipTo(head, LINKED_LIST_HEAD)
    tail.createRelationshipTo(tail, LINKED_LIST_TAIL)
    head.createRelationshipTo(tail, LINKED_LIST_NEXT)
  }

  // Destroy whole list.
  def destroy(entry: Node) {
    destroyEntries(getHead(entry))
  }

  private def destroyEntries(entry: Node) {
    entry.getSingleRelationship(LINKED_LIST_HEAD, Direction.OUTGOING).delete()
    entry.getSingleRelationship(LINKED_LIST_TAIL, Direction.OUTGOING).delete()
    val nextRel = entry.getSingleRelationship(LINKED_LIST_NEXT, Direction.OUTGOING)
    if (nextRel != null) {
      nextRel.delete()
      destroyEntries(nextRel.getEndNode())
    }
  }

  // Inserts entry between previous and the following node.
  def insertAfter(previous: Node, entry: Node): Unit = {
    if (entry.getSingleRelationship(LINKED_LIST_HEAD, Direction.OUTGOING) != null) {
      throw new IllegalArgumentException("Entry is already part of a list.")
    }

    entry.createRelationshipTo(getHead(previous), LINKED_LIST_HEAD)
    entry.createRelationshipTo(getTail(previous), LINKED_LIST_TAIL)

    val nextRel = previous.getSingleRelationship(LINKED_LIST_NEXT, Direction.OUTGOING)
    nextRel.delete

    previous.createRelationshipTo(entry, LINKED_LIST_NEXT)
    entry.createRelationshipTo(nextRel.getEndNode, LINKED_LIST_NEXT)
  }

  // Inserts entry between next and the node before.
  def insertBefore(next: Node, entry: Node): Unit = {
    if (entry.getSingleRelationship(LINKED_LIST_HEAD, Direction.OUTGOING) != null) {
      throw new IllegalArgumentException("Entry is already part of a list.")
    }

    entry.createRelationshipTo(getHead(next), LINKED_LIST_HEAD)
    entry.createRelationshipTo(getTail(next), LINKED_LIST_TAIL)

    val nextRel = next.getSingleRelationship(LINKED_LIST_NEXT, Direction.INCOMING)
    nextRel.delete

    nextRel.getStartNode.createRelationshipTo(entry, LINKED_LIST_NEXT)
    entry.createRelationshipTo(next, LINKED_LIST_NEXT)
  }

  // Remove entry and return tail node. Do not execute on head or tail node.
  def remove(entry: Node) = {
    val headRel = entry.getSingleRelationship(LINKED_LIST_HEAD, Direction.OUTGOING)
    val tailRel = entry.getSingleRelationship(LINKED_LIST_TAIL, Direction.OUTGOING)
    val outgoingNextRel = entry.getSingleRelationship(LINKED_LIST_NEXT, Direction.OUTGOING)
    val incomingNextRel = entry.getSingleRelationship(LINKED_LIST_NEXT, Direction.INCOMING)

    headRel.delete
    tailRel.delete
    outgoingNextRel.delete
    incomingNextRel.delete
    incomingNextRel.getStartNode.createRelationshipTo(outgoingNextRel.getEndNode, LINKED_LIST_NEXT)

    tailRel.getEndNode
  }

  // Get head entry.
  def getHead(entry: Node) = {
    entry.getSingleRelationship(LINKED_LIST_HEAD, Direction.OUTGOING).getEndNode
  }

  // Get tail entry.
  def getTail(entry: Node) = {
    entry.getSingleRelationship(LINKED_LIST_TAIL, Direction.OUTGOING).getEndNode
  }

  // Get previous entry. Do not execute on head node.
  def getPrevious(entry: Node) = {
    entry.getSingleRelationship(LINKED_LIST_NEXT, Direction.INCOMING).getStartNode
  }

  // Get all previous entries (including current, excluding head).
  def getAll(current: Node): List[Node] = {
    val nextRel = current.getSingleRelationship(LINKED_LIST_NEXT, Direction.INCOMING)
    if (nextRel == null) {
      Nil
    } else {
      current :: getAll(nextRel.getStartNode)
    }
  }

  // Searches backwards from tail until filter returns true and returns the selected node.
  // The filter must always return true for head node.
  def find(tail: Node, filter: (Node) => Boolean): Node = {
    val previous = getPrevious(tail)
    if (filter(previous)) {
      previous
    } else {
      find(previous, filter)
    }
  }

}