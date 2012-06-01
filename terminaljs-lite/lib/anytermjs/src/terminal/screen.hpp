/* 
 * File:   screen.hpp
 * Author: vic
 *
 * Created on January 5, 2012, 5:49 PM
 */

#ifndef SCREEN_HPP
#define	SCREEN_HPP

#include <vector>
#include <algorithm>

#include "Cell.hh"

namespace KFM{namespace Terminal{

    class CScreen
    {
    public:
        typedef std::vector<Cell> row_t;
    private:
        std::pair<size_t,size_t> mSize;
        std::vector<row_t*> mCells;
        std::pair<size_t,size_t> mCursor;
        bool mCursorVisible;
        std::pair<size_t,size_t> mScrollingRegion;
        size_t mWrap;
    public:
        
        CScreen(size_t rows,size_t cols);
        CScreen(CScreen &);
        ~CScreen();
        std::pair<size_t,size_t> getSize();
        void setSize(size_t,size_t);
        size_t numRows();
        size_t numCols();
        Cell &getCell(size_t,size_t);
        std::pair<size_t,size_t> getCursor();
        size_t getCursorRow();
        size_t getCursorCol();
        void setCursorRow(size_t row);
        void setCursorCol(size_t col);
        void setCursor(size_t,size_t);
        bool isCursorVisible();
        void setCursorVisible(bool enable=true);
        void setScrollingRegion(size_t top,size_t bottom);
        void operator = (CScreen &screen);
        void copy(CScreen &screen);
        void scrollUp( size_t n = 1);
        void scrollDown(size_t n=1);
        void cursorUp(size_t n=1);
        void cursorDown(size_t n=1);
        void cursorLeft(size_t n=1);
        void cursorRight(size_t n=1);
        void pushChar(ucs4_char ,Attributes &);
        void clear();
        void reset();
        
    //protected:
        
        void clearRow(size_t row);
        void clipCursor();
    };

}} //end of namespace KFM::Terminal

#endif	/* SCREEN_HPP */

