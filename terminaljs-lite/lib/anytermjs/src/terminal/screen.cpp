#include <stdexcept>
#include "defines.hpp"
#include "screen.hpp"
#define _KFM_LOG_ENABLED_ 0
#include "log/log.hpp"
#include <assert.h>
#include <iostream>

//#define KFM_LOG_DBG(x) std::cout<<"\n"<<x<<std::flush

namespace KFM{namespace Terminal{

    CScreen::CScreen(size_t rows,size_t cols) : mCursorVisible(true), mWrap(0)
    {
        mScrollingRegion=std::make_pair(0,rows-1);
        mSize=std::make_pair(rows,cols);
        mCursor=std::make_pair(0,0);
        for(int i=0; i<rows; i++)
        {
            mCells.push_back(new row_t(cols));
        }
        KFM_LOG_DBG("new screen created with {rows:<<"<<rows<<",cols:"<<cols<<"}");
    }
    
    CScreen::~CScreen()
    {
        while(!mCells.empty())
        {
            std::vector<row_t*>::iterator it=mCells.begin();
            (*it)->clear();
            delete *it;
            mCells.erase(it);
        }
    }
    
    CScreen::CScreen(CScreen &s)
    {
        copy(s);
    }
 
    void CScreen::operator =(CScreen& s)
    {
        copy(s);
    }
  
    void CScreen::copy(CScreen& s)
    {

        int i=0;
        if(mCells.size())
        {
            if(mSize.second<s.mSize.second)
            {
                for(std::vector<row_t *>::iterator it=mCells.begin();it!=mCells.end();++it)
                {
                    (*it)->resize(s.mSize.second);
                }   
            }
            for (i = 0; (i < s.mCells.size()) && (i< mCells.size()); i++)
            {
                for(int j=0;j<s.mSize.second;j++)
                {
                    (*mCells[i])[j]=(*s.mCells[i])[j];
                }
            }
        }
        
        for(;i<s.mCells.size();i++)
        {
            mCells.push_back(new row_t(*(s.mCells[i])));
        }
    
        mSize.first = s.mSize.first;
        mSize.second = s.mSize.second;
        mCursor.first = s.mCursor.first;
        mCursor.second = s.mCursor.second;
        mCursorVisible = s.mCursorVisible;
        mScrollingRegion.first = s.mScrollingRegion.first;
        mScrollingRegion.second = s.mScrollingRegion.second; 
        mWrap=s.mWrap;

    }
    
    std::pair<size_t,size_t> CScreen::getSize()
    {
        return mSize;
    }
    void CScreen::setSize(size_t rows,size_t cols)
    {
        if (rows <= 0) rows = 1;
        if (cols <= 0) cols = 1;

        int d = std::min(rows,mCells.size());
        for (int i = 0; i < d; i++) 
        {
            mCells[i]->resize(cols, L' ');
        }
        
        //alloc some more space
        if (rows > mCells.size())
        {
            for (int i = mCells.size(); i <= rows; i++)
            {
                mCells.push_back(new row_t(cols, L' '));
            }
        }
        else
        {
            for(int j=0;j<rows-mCells.size();j++)
            {
                row_t *row = mCells.back();
                row->clear();
                delete row;
                mCells.pop_back();
            }
        }

        mSize.first = rows;
        mSize.second = cols;
        mScrollingRegion.first=0;
        mScrollingRegion.second=rows-1;
		clipCursor();

    }

    void CScreen::clipCursor()
    {   
        KFM_LOG_DBG("clip cursor cursor{row:"<<mCursor.first<<",col:"<<mCursor.second<<"} size{rows:"<<mSize.first<<",cols:"<<mSize.second<<"} scrolling region {top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}");
        if(mCursor.second>=mSize.second)
        {
        	KFM_LOG_DBG("cursor col overflow cursor {row:"<<mCursor.first<<",col:"<<mCursor.second<<"}, size {rows:"<<mSize.first<<",cols:"<<mSize.second<<"}, scrolling region {top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}, adjusting ...");
            mCursor.second=0;
            mCursor.first++;
        }
        if(mCursor.first>=mScrollingRegion.second)
        {
        	KFM_LOG_DBG("cursor row overflow cursor {row:"<<mCursor.first<<",col:"<<mCursor.second<<"}, size {rows:"<<mSize.first<<",cols:"<<mSize.second<<"}, scrolling region {top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}, adjusting ...");
            mCursor.first=mScrollingRegion.second;
        }
    }
    Cell & CScreen::getCell(size_t row,size_t col)
    {
        if(row>=mSize.first)
        {
            row=mSize.first - 1;
        }
        if(col>=mSize.second)
        {
            col=mSize.second - 1;
        }
        return (*mCells[row])[col];
    }
    

    
    std::pair<size_t,size_t> CScreen::getCursor()
    {
        return mCursor;
    }
    
    size_t CScreen::getCursorRow()
    {
        return mCursor.first;
    }
    
    size_t CScreen::getCursorCol()
    {
        return mCursor.second;
    }
    
    void CScreen::setCursorRow(size_t row)
    {
        KFM_LOG_DBG("set cursor row to : "<<row);
        if(row<mScrollingRegion.first)
        {
            KFM_LOG_DBG("scrolling region underflow top:"<<mScrollingRegion.first);
            row=mScrollingRegion.first;
        }
        if(row>mScrollingRegion.second)
        {
          KFM_LOG_DBG("scrolling region overflow bottom:"<<mScrollingRegion.second);
          row=mScrollingRegion.second;
        }
        mCursor.first=row;
    }
    
    void CScreen::setCursorCol(size_t col)
    {
      KFM_LOG_DBG("set cursor col to : "<<col);
        if(col>=mSize.second)
        {
            KFM_LOG_DBG("cursor overflow, total cols: "<<mSize.second);
            col=mSize.second-1;
        }
        mCursor.second=col;
    }
    void CScreen::setCursor(size_t row, size_t col)
    {
    	KFM_LOG_DBG("set cursor to row="<<row<<" col="<<col);
        setCursorRow(row);
        setCursorCol(col);
    }
    
    void CScreen::setCursorVisible(bool enable)
    {
        mCursorVisible=enable;
    }
    
    bool CScreen::isCursorVisible()
    {
        return mCursorVisible;
    }
    
    
    void CScreen::clearRow(size_t pos)
    {
    	KFM_LOG_DBG("clear row : "<<pos<<" rows size{rows:"<<mSize.first<<",cols:"<<mSize.second<<"} scrolling region{top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}, cache{rows:"<<mCells.size()<<",cols:"<<mCells[0]->size()<<"}");
        if(pos>=mCells.size())
        {
           // throw std::runtime_error("Screen row raise");
			return ; //silently drop request
        }
        row_t *row=mCells[pos];
        for(std::vector<Cell>::iterator it=row->begin();it!=row->end();++it)
        {
            it->c=L' ';
        }
    }

    void CScreen::scrollDown( size_t n)
    {
        KFM_LOG_DBG("scrolling down with "<<n<<" rows size{rows:"<<mSize.first<<",cols:"<<mSize.second<<"} scrolling region{top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}, cache{rows:"<<mCells.size()<<",cols:"<<mCells[0]->size()<<"}");
        if(!n||!mScrollingRegion.second) return;
        int s=mScrollingRegion.second-mScrollingRegion.first+1;
        if(n>s) n=s;
        std::rotate(mCells.begin() + mScrollingRegion.first, mCells.begin() + mScrollingRegion.first + n, mCells.begin() + mScrollingRegion.second  + 1);

        for (int r = mScrollingRegion.second + 1 - n; r <= mScrollingRegion.second; ++r)
        {
            clearRow(r);
        }
    }
    
    void CScreen::scrollUp( size_t n )
    {
        KFM_LOG_DBG("scrolling up with "<<n<<" rows");
        if(!n||!mScrollingRegion.second) return;
        int s=mScrollingRegion.second-mScrollingRegion.first+1;
        if(n>s) n=s;
        std::rotate(mCells.begin() + mScrollingRegion.first, mCells.begin() + mScrollingRegion.second + 1 - n,mCells.begin() + mScrollingRegion.second + 1);
        for(int r = mScrollingRegion.first; r < mScrollingRegion.first + n; ++r)
        {
            clearRow(r);
        }
        
    }

    size_t CScreen::numCols()
    {
        return mSize.second;
    }
    
    size_t CScreen::numRows()
    {
        return mSize.first;
    }
    
    void CScreen::setScrollingRegion(size_t top,size_t bottom)
    {
        KFM_LOG_DBG("setting scrolling region {top:"<<top<<",bottom:"<<bottom<<"} size {rows"<<mSize.first<<",cols: "<<mSize.second<<"}");
        if(top>mSize.first)
        {
          top=mSize.first;
        }
        if(bottom>mSize.first)
        {
          bottom=mSize.first;
        }
        mScrollingRegion.first = top?(top -1):0;
        mScrollingRegion.second = bottom?(bottom -1):0;
    }
    
    void CScreen::cursorUp(size_t n)
    {
    	KFM_LOG_DBG("cursor up with "<<n<<" rows , current cursor {row:"<<mCursor.first<<",col:"<<mCursor.second<<"}, scrolling region {top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}, size {rows:"<<mSize.first<<",cols:"<<mSize.second<<"}");
      if(!n) return;
    	if(mCursor.first<(mScrollingRegion.first+n))
        {
            scrollUp(mScrollingRegion.first-mCursor.first +n);
            mCursor.first = mScrollingRegion.first;
        }
        else
        {
            mCursor.first-=n;
        }
        
    }
    
    void CScreen::cursorDown(size_t n)
    {
        if(n==0) return;
        KFM_LOG_DBG("cursor down with "<<n<<" rows , current cursor {row:"<<mCursor.first<<",col:"<<mCursor.second<<"}, scrolling region {top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}, size {rows:"<<mSize.first<<",cols:"<<mSize.second<<"}");
        if((n+mCursor.first)>mScrollingRegion.second)
        {
            scrollDown(n+mCursor.first-mScrollingRegion.second);
            mCursor.first = mScrollingRegion.second;
        }
        else
        {
            mCursor.first+=n;
        }
        
    }
    
    void CScreen::cursorLeft(size_t n)
    {
        KFM_LOG_DBG("cursor left with "<<n<<" cells , current cursor {row:"<<mCursor.first<<",col:"<<mCursor.second<<"}");
        if(n==0) return;
        if(n>mCursor.second)
        {
            cursorUp();
            size_t l=n-mCursor.second;
            mCursor.second=mSize.second-1;
            cursorLeft(l);
        }
        else
        {
            mCursor.second-=n;
        }
    }
    
    void CScreen::cursorRight(size_t n)
    {
        KFM_LOG_DBG("cursor right with "<<n<<" cells, current cursor {row:"<<mCursor.first<<",col:"<<mCursor.second<<"}");
        if(n==0) return;
        
        if((n+mCursor.second)>mSize.second)
        {
            cursorDown();
            size_t r = n + mCursor.second - mSize.second;
            mCursor.second=0;
            cursorRight(r);
        }
        else
        {
            mCursor.second+=n;
        }
    }
    
    void CScreen::clear()
    {
        KFM_LOG_DBG("clearing screen");
        for(int i=0;i<mSize.first;i++)
        {
            clearRow(i);
        }
        mCursor.first=0;
        mCursor.second=0;

    }
    
    void CScreen::reset()
    {
        KFM_LOG_DBG("reseting screen");
        clear();
        mCursorVisible=true;
        mScrollingRegion.first=0;
        mScrollingRegion.second=mSize.first-1;
    }
    
    void CScreen::pushChar(ucs4_char c,Attributes &a)
    {
        KFM_LOG_DBG("pushing new char  cursor={row:"<<mCursor.first<<",col:"<<mCursor.second<<"} size={rows:"<<mSize.first<<",cols:"<<mSize.second<<"} scrolling region: {top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}");
        if (mCursor.second>=mSize.second)
        {
            KFM_LOG_DBG("row overflow, scrolling down : scrolling region={top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"}");
            mCursor.second = 0;
            mCursor.first++;
            if (mCursor.first>=mScrollingRegion.second)
            {
                scrollDown();
                mCursor.first = mScrollingRegion.second;
            }
        }

        KFM_LOG_DBG("cursor adjusted; size={rows:"<<mSize.first<<",cols:"<<mSize.second<<"} cache size {rows:"<<mCells.size()<<",cols:"<<mCells[0]->size()<<"} scrolling region {top:"<<mScrollingRegion.first<<",bottom:"<<mScrollingRegion.second<<"} cursor{row:"<<mCursor.first<<",col:"<<mCursor.second<<"}");
        assert(mCursor.first<mCells.size());
        assert(mCursor.second<mCells[mCursor.first]->size());
        Cell &cell=(*mCells[mCursor.first])[mCursor.second];
        cell.c=c;
        cell.attrs=a;
        mCursor.second++;
        KFM_LOG_DBG("char pushed, current cursor position {row:"<<mCursor.first<<",col:"<<mCursor.second<<"}");
    }

}} //end of namespace KFM::Terminal
