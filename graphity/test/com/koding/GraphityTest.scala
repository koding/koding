package com.koding

object GraphityTest {

  def main(args: Array[String]) {
    org.scalatest.run.main(Array("com.koding.GraphityTestSuite", "com.koding.LinkedListTestSuite"))
  }

}