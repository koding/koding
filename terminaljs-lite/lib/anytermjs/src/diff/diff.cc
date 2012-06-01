// common/diff.cc
// This file is part of Anyterm; see http://anyterm.org/
// (C) 2005 Philip Endecott

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


#include "diff.hh"

#include <string>
#include <vector>
using namespace std;


namespace DiffAlgo {

  // The algorithm used is the one described in
  //    "An O(ND) Difference Algorithm and Its Variations"
  //    by Eugene W Myers.
  //    (Postscript can be found on Myers' web page.)

  // O(ND) refers to N = the size of the input (the sum of the two)
  // and D = the length of the resulting "edit script", i.e. the
  // number of differences.  The paper notes that the expected
  // performance is O(N+D^2), with O(ND) being a pathological case.
  // This is the complexity for the first phase of the computation in
  // which the "edit script size" is found.  There is a second phase
  // during which the actual "edit script" is determined.  This runs
  // in O(N) time, but has space complexity O(D^2) (or worse O(ND) if
  // the implementation is naive).  The paper presents an alternative
  // implementation for the second phase in section 4b which has O(N)
  // space requirements.  This is NOT implemented here.  It is likely
  // that for non-trivial applications, space complexity is likely to
  // be a concern.  Comparing sequences of only a few thousand items
  // with signficant differences, i.e. an "edit script length" of a
  // few thousand will consume megabytes, yet execution time is only
  // seconds.  (On the other hand, when the inputs are similar, space
  // performance is good.)

  // Myers and others have proposed improvements to this algorithm,
  // including one in the following paper:
  //   "An O(NP) Sequence Comparison Algorithm"
  //   Sun Wu, Udi Manber, Gene Myers
  //   (Postscript ditto).

  // In this case, P is the number of deletions in the "edit script",
  // which is less than the size of the script D.  This has NOT been
  // implemented here.

  // Here is a quick overview of the algorithm:

  // The two input strings are A and B.  Imagine a grid with A
  // labelling the columns and B labelling the rows.  There are
  // additional "zeroth" rows and columns.  Say A = abc and B = baba:

  //       a b c
  //     . . . .
  //   b . . * .
  //   a . * . .
  //   b . . * .
  //   a . * . .
  
  // The points where the labels on the rows and columns match are
  // marked specially.

  // The aim is to find a path from the top-left to the bottom-right
  // of this grid in the following way:
  //  - Rightward horizontal moves indicate taking an element from
  //  sequence A.
  //  - Downward vertical moves indicate taking an element from
  //  sequence B.
  //  - Down-Right diagonal moves indicate taking an element common to
  //  A and B.
  // Horizontal and vertical moves are always allowed.  Diagonal moves
  // are only allowed in order to reach the (specially marked) match
  // points.  The aim is to find a path obeying these constraints that
  // has the fewest horizontal and vertical moves, and hence the most
  // diagonal moves.
  // In the example above, a possible solution is as follows:

  //       a b c
  //     + . . .
  //   b | . * .
  //   a .\* . .
  //   b . .\*-.
  //   a . * . |

  // (i.e.: vertically to take b, diagonally twice to take a and b,
  // horizontally to take c, and vertically to take a.)

  // The algorithm searches in a greedy fashion, that is, it is
  // breadth-first when it is doing badly, but then depth-first once
  // it is "on to a good thing" (i.e. a diagonal).  It expands a
  // "frontier" across the grid from the top-left towards the bottom
  // right.  Once the frontier hits the bottom-right, the problem is
  // solved.

  // Giving each horizontal and vertical move a cost of one and each
  // diagonal move a cost of zero, all points on the frontier during a
  // particular iteration have the same cost.  The variable d is used
  // to refer to the costs (d is the number of differences).

  // Points on the grid can be referred to using (x,y) coordinates.
  // Row/column 0 are necessarily "empty" and do not correspond to
  // elements of A or B.  Care is needed with off-by-one errors, since
  // the sequences A and B are indexed from 0.

  // Points can also be referred to using one or other of x and y (x
  // by convention) and the "diagonal index", k, defined by k=x-y.
  
  // The point about the diagonal index is that the frontier will
  // always expand in such a way that it cuts each diagonal exactly
  // once:

  //          k
  //         2
  //        1  /      .
  //       0   \      .
  //     -1     \     .
  //    -2  /\/\/     .
  //       /          .

  // So we can record the position of the frontier by giving the
  // x-coordinate for each value of k.  In the code, the vector V
  // records these values.

  // Thinking of "snakes and ladders", diagonals are named "snakes"
  // (though surely, since they lead toward the goal, they should be
  // ladders?).  A "snake" is a (possibly empty or singleton) sequence
  // of diagonals.

  // Once the frontier has reached the target, a second phase of the
  // algorithm identifies the optimal path by studying saved copies of
  // the V vector from each step of the expansion.  This is the
  // space-hungry step mentioned above.

  // To reduce the space-hungryness from O(ND) to O(D^2), something of
  // a hack is used.  The first phase is run twice.  In the first run,
  // nothing is stored (so memory use is moderate).  At the end of
  // this run, the "edit script length" is known.  In the second run,
  // the V vectors are stored but this knowledge is used to limit
  // their size.



  // The Differ class is template-parameterised by the sequence type
  // that it operates on.  This is normally string, but if you want to
  // use a different type, you should just be able to create a Differ
  // object specifying a different type.  vector<something> should
  // work, as long as operator= is defined on 'something'.  See the
  // end of the file for how Differ is used.

  template <typename SEQ>
  class Differ {

  private:
    const SEQ& A;    // Input sequences
    const SEQ& B;
    const int N;     // length of A
    const int M;     // length of B
    const int max_D;
    bool store;

    // Output
    typename fragment_seq<SEQ>::Type& result;

    // Ideally V would be an array indexed from -(M+N) to (M+N)
    // inclusive, but we only have zero-indexed arrays.  So we use a
    // zero-indexed array and apply an offset.

    const int V_size;
    const int V_offset;
    
    typedef vector<int> V_impl_t;
    V_impl_t V_impl;
    int& V ( int k ) { return V_impl[V_offset+k]; }
    

    typedef vector<V_impl_t> stored_V_impls_t;
    stored_V_impls_t stored_V_impls;
    int stored_V ( int d, int k ) const { return (stored_V_impls[d])[V_offset+k]; }
    
    // This is filled in when solve() finishes.  If all that is wanted
    // is to know the distance between the two inputs, there is no
    // need to call find_trace() at all; just read this using
    // get_edit_distance().
    int edit_distance;


    // Append an item to the result, with a tag.
    // If the tag matches the tag of the current end of the result, it
    // is merged with it.
    void append_result ( fragment_tag tag, typename SEQ::value_type datum )
    {	
      if (!result.empty() && (result.back().first == tag)) {
	result.back().second.push_back(datum);
      } else {
	result.push_back(make_pair(tag,SEQ(1,datum)));
      }
    }
    
    // Follow any snake from (k,x) to its end, and return the x
    // coordinate at the end.
    int follow_snake ( int k, int x )
    {
      int y = x - k;
      while ( (x>=0) && (x<N) && (y>=0) && (y<M) && (A[x]==B[y]) ) {
	++x;
	++y;
      }
      return x;
    }
    
    // Follow any snake from (k,x) to its end, recording the data in
    // the result with tag "common".
    void get_snake ( int k, int x )
    {
      int y = x - k;
      while ( (x>=0) && (x<N) && (y>=0) && (y<M) && (A[x]==B[y]) ) {
	append_result(common,A[x]);
	++x;
	++y;
      }
    }

    
    // Find and record a trace from (0,0) to the point on diagonal k
    // with cost d.  (Recursive)
    void find_trace_r ( int d, int k )
    {
      if (d==0) {
	get_snake(0,0);
	return;
	
      } else {

	// Look up x coordinate in saved V for cost=d in diagonal k.
	int x = stored_V(d,k);

	// How did we get to (k,x)?
	// Either:
	//   - A vertical move from (k+1,something), possibly followed by a
	//   "snake" along diagonal k.
	//   - A horizontal move from (k-1,something), possibly
	//   followed by a "snake" along diagonal k.

	// To find out which, we look up V(k) for d-1 in diagonals k+1
	// and k-1, and see if snake-slides from either of those
	// points would get to to (k,x).  (One or other must do, so we
        // now only do one check.)

	// Notation: R = point before H or V move;
	//           S = point after H or V move;
	//           T = point after subsequent snake.

	// Start by checking for a vertical move
	int Rx = stored_V(d-1,k+1);
	int Sx = Rx;
	int Tx = follow_snake(k,Sx);
	
	if (Tx == x) {
	  // OK, did a vertical move.  Find how we got to that point.
	  find_trace_r ( d-1, k+1 );
	  // Find the data at the end of that move
	  int Ry = Rx - (k+1);
	  int Sy = Ry +1;
	  typename SEQ::value_type d = B[Sy-1];
	  // Record vertical move plus data.
	  append_result(from_b,d);
	  // Record any snake that followed it.
	  get_snake(k,Sx);
	  
	} else {

	  // It must have been a horizontal move.
	  int Rx = stored_V(d-1,k-1);
	  int Sx = Rx + 1;
	
	  // Find how we got to that point.
	  find_trace_r ( d-1, k-1 );
	  // Find the data at the end of that move
	  typename SEQ::value_type d = A[Sx-1];
	  // Record horizontal move plus data.
	  append_result(from_a,d);
	  // Record any snake that followed it.
	  get_snake(k,Sx);
	    
	}
      }
    }

    
  public:

    // Constructor, takes input sequences and reference to output.
    // Optionally takes store flag and max_D.
    Differ ( const SEQ& a, const SEQ& b, typename fragment_seq<SEQ>::Type& r,
	     bool s = true, int md = -1):
      A(a),
      B(b),
      N(A.size()),
      M(B.size()),
      max_D((md==-1)?(M+N):(min(md,M+N))),
      store(s),
      result(r),
      V_size(max(2*(max_D)+1,2)),  // 2 allows for d=0 V(1) special case
      V_offset(max_D),
      V_impl(V_size)
    {}

    class max_D_exceeded {};  // Exception thrown if solution has not
			      // been found after max_D
			      // frontier-expansion iterations.

    // Perform the first phase of the algorithm, expanding the
    // frontier.
    // This function is essentially what is described in Figure 2 of
    // Myers' paper.
    void solve ( void )
    {
      // The normal operation is (H or V) then any diagonal then repeat.
      // But this is broken if the first diagonal starts from the origin (e.g. for equal strings).
      // The following is a hack that works around that:
      V(1) = 0;
      // But this requires that V is large enough for this extra element.

      // Loop for increasing values of D until target reached
      int D = -1;
      bool done=false;
      while (!done) {
	++D;
	if (D>max_D) {
	  throw max_D_exceeded();
	}

	// Scan across the width of the frontier
	for ( int k = -D; k <= D; k += 2 ) {

	  // Find a new x value for this point on the frontier.
	  // Special cases for either end.
	  // Otherwise, move horizontally or vertically from a neighbour.
	  int x;
	  if ( (k==-D) || ((k!=D) && (V(k-1)<V(k+1))) ) {
	    // vertical move
	    x = V(k+1);
	  } else {
	    // horizontal move
	    x = V(k-1)+1;
	  }

	  // Having made the horizontal or vertical move, follow any
	  // diagonal "snakes" from this point.
	  int y = x - k;
	  while ( (x<N) && (y<M) && (A[x]==B[y]) ) {
	    ++x;
	    ++y;
	  }

	  // Store the new x value for this point on the frontier.
	  V(k) = x;

	  // Test for reaching target
	  if ( (x>=N) && (y>=M) ) {
	    done = true;
	    // We could probably leave the inner loop at this point,
	    // but I'm not certain it's safe, and it certainly makes
	    // debugging harder when only some of the points have been
	    // updated, so don't bother.
	    //break;
	  }
	}

	// Save a copy of V for use during the second phase.
	if (store) {
	  stored_V_impls.push_back(V_impl);
	}
      }
      
      edit_distance = D;
    }


    void find_trace ( void )
    {
      find_trace_r ( edit_distance, N-M );
    }
    
    
    int get_edit_distance(void) { return edit_distance; }
  };


  
  void make_trivial_solution ( const string& A, const string& B, string_fragment_seq& result )
  {
    result.push_back(make_pair(from_a,A));
    result.push_back(make_pair(from_b,B));
  }


  void string_diff ( const string& A, const string& B, string_fragment_seq& result )
  {
    // Consider time efficiency.  Aim not to take more than this much
    // time (arbitary units).  Return a sub-optimal solution if this
    // time is exceeded.
    const int max_time = 1000;

    // Consider space efficiency.  Aim not to use more than this much
    // memory (arbitary units).  Take more time or return a
    // sub-optimal solution if this much memory is exceeded.
    const int max_mem = 10000000;

    // Consider changing the above settings if "top" shows that the
    // apache frontend request-handling processes are using more
    // memory or CPU time than you would like.

    // Reducing them means that Anyterm will give up looking for an
    // edit script and just send the complete new screen sooner.  So
    // making them too low will use more network bandwidth.  On the
    // other hand, for a fast local network, you might get a faster
    // response with a lower max_time setting.


    try {

      int sz = A.size() + B.size();
      // If input is small, i.e. N^2 is acceptable, we don't worry about
      // space complexity.  (This will take O(ND) space, but D could
      // equal N.)
      if ((sz*sz)<max_mem) {
	Differ<string> d1(A,B,result,true,max_time);
	d1.solve();
	d1.find_trace();
	return;
      }
      
      // If input is larger, do a first pass to find the edit distance:
      Differ<string> d2(A,B,result,false,max_time);
      d2.solve();

      // We could now solve this with space complexity O(ND), if that
      // were acceptable:
      if (sz*d2.get_edit_distance()<max_mem) {
	Differ<string> d3(A,B,result,true,d2.get_edit_distance());
	d3.solve();
	d3.find_trace();
	return;
      }
      
      // If even O(ND) is not acceptable, we give up and return a result
      // indicating no common subset:

      make_trivial_solution(A,B,result);
    }

    catch (Differ<string>::max_D_exceeded) {
      make_trivial_solution(A,B,result);
    }
  }



  void make_trivial_solution ( const ucs4_string& A, const ucs4_string& B, ucs4_string_fragment_seq& result )
  {
    result.push_back(make_pair(from_a,A));
    result.push_back(make_pair(from_b,B));
  }


  void ucs4_string_diff ( const ucs4_string& A, const ucs4_string& B, ucs4_string_fragment_seq& result )
  {
    // Consider time efficiency.  Aim not to take more than this much
    // time (arbitary units).  Return a sub-optimal solution if this
    // time is exceeded.
    const int max_time = 300;

    // Consider space efficiency.  Aim not to use more than this much
    // memory (arbitary units).  Take more time or return a
    // sub-optimal solution if this much memory is exceeded.
    const int max_mem = 10000000;

    // Consider changing the above settings if "top" shows that the
    // apache frontend request-handling processes are using more
    // memory or CPU time than you would like.

    // Reducing them means that Anyterm will give up looking for an
    // edit script and just send the complete new screen sooner.  So
    // making them too low will use more network bandwidth.  On the
    // other hand, for a fast local network, you might get a faster
    // response with a lower max_time setting.


    try {

      int sz = A.size() + B.size();
      // If input is small, i.e. N^2 is acceptable, we don't worry about
      // space complexity.  (This will take O(ND) space, but D could
      // equal N.)
      if ((sz*sz)<max_mem) {
	Differ<ucs4_string> d1(A,B,result,true,max_time);
	d1.solve();
	d1.find_trace();
	return;
      }
      
      // If input is larger, do a first pass to find the edit distance:
      Differ<ucs4_string> d2(A,B,result,false,max_time);
      d2.solve();

      // We could now solve this with space complexity O(ND), if that
      // were acceptable:
      if (sz*d2.get_edit_distance()<max_mem) {
	Differ<ucs4_string> d3(A,B,result,true,d2.get_edit_distance());
	d3.solve();
	d3.find_trace();
	return;
      }
      
      // If even O(ND) is not acceptable, we give up and return a result
      // indicating no common subset:

      make_trivial_solution(A,B,result);
    }

    catch (Differ<ucs4_string>::max_D_exceeded) {
      make_trivial_solution(A,B,result);
    }
  }

};


