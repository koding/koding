package app

import (
	"testing"
	"time"
)

func TestDeferTimeStart(t *testing.T) {
	const timeToWait = 10 * time.Millisecond
	now := time.Now()
	afterC := make(chan time.Time)

	dt := NewDeferTime(timeToWait, func() {
		afterC <- time.Now()
	})
	defer dt.Close()

	dt.Start()

	select {
	case after := <-afterC:
		if passed := after.Sub(now); passed < timeToWait {
			t.Fatalf("want passed > %v; got %v", timeToWait, passed)
		}
	case <-time.After(2 * timeToWait):
		t.Fatalf("test timed out after %v", 2*timeToWait)
	}
}

func TestDeferTimeStartStop(t *testing.T) {
	const timeToWait = 10 * time.Millisecond
	afterC := make(chan time.Time)

	dt := NewDeferTime(timeToWait, func() {
		afterC <- time.Now()
	})
	defer dt.Close()

	dt.Start()
	time.Sleep(timeToWait / 2)
	dt.Stop()
	dt.Stop()

	select {
	case <-afterC:
		t.Fatalf("test function should not be called")
	case <-time.After(2 * timeToWait):
	}
}

func TestDeferTimeStartTwice(t *testing.T) {
	const timeToWait = 10 * time.Millisecond
	now := time.Now()
	afterC := make(chan time.Time)

	dt := NewDeferTime(timeToWait, func() {
		afterC <- time.Now()
	})
	defer dt.Close()

	dt.Start()

	select {
	case after := <-afterC:
		if passed := after.Sub(now); passed < timeToWait {
			t.Fatalf("want passed > %v; got %v", timeToWait, passed)
		}
	case <-time.After(2 * timeToWait):
		t.Fatalf("test timed out after %v", 2*timeToWait)
	}

	dt.Start()

	select {
	case after := <-afterC:
		if passed := after.Sub(now); passed < 2*timeToWait {
			t.Fatalf("want passed > %v; got %v", 2*timeToWait, passed)
		}
	case <-time.After(3 * timeToWait):
		t.Fatalf("test timed out after %v", 3*timeToWait)
	}
}

func TestDeferTimeShift(t *testing.T) {
	const timeToWait = 10 * time.Millisecond
	afterC := make(chan time.Time)

	dt := NewDeferTime(timeToWait, func() {
		afterC <- time.Now()
	})
	defer dt.Close()

	dt.Start()
	time.Sleep(timeToWait / 2)
	dt.Start()
	time.Sleep(timeToWait / 2)
	now := time.Now()
	dt.Start()

	select {
	case after := <-afterC:
		if passed := after.Sub(now); passed < timeToWait {
			t.Fatalf("want passed > %v; got %v", timeToWait, passed)
		}
	case <-time.After(2 * timeToWait):
		t.Fatalf("test timed out after %v", 2*timeToWait)
	}
}
