#include "screen_stream.hpp"
#include <string>
#include <sstream>

#define _KFM_LOG_ENABLED_ 0
#include "log/log.hpp"

namespace KFM{namespace Terminal{
    
    CScreenStream::CScreenStream(CScreen &s): mScreen(s),mCharsetMode(0)
    ,mCrlfMode(false),mEscState(normal),mPc850ToUcs4("850", UCS4_NATIVE)
    ,mNParams(0)
    {
        mSavedCursor = std::make_pair(0,0);
        mCharsetModes[0] = cs_normal;
        mCharsetModes[1] = cs_vt100gr;
    }
    
    CScreenStream::~CScreenStream()
    {}
    
    CScreen & CScreenStream::getScreen()
    {
        return mScreen;
    }


    void CScreenStream::writeNormalChar(ucs4_char c)
    {
        switch (mCharsetModes[mCharsetMode])
        {
            case cs_vt100gr:
                switch (c)
                {
                    case 'j': c = L'\u255b';
                        break; // lower right corner
                    case 'k': c = L'\u2510';
                        break; // upper right corner
                    case 'l': c = L'\u250c';
                        break; // upper left corner
                    case 'm': c = L'\u2514';
                        break; // lower left corner
                    case 'n': c = L'\u253c';
                        break; // crossing lines
                    case 'o': c = L'\u2500';
                        break; // horizontal line - scan 1
                    case 'p': c = L'\u2500';
                        break; // horizontal line - scan 3
                    case 'q': c = L'\u2500';
                        break; // horizontal line - scan 5
                    case 'r': c = L'\u2500';
                        break; // horizontal line - scan 7
                    case 's': c = L'\u2500';
                        break; // horizontal line - scan 9
                    case 't': c = L'\u251c';
                        break; // left T
                    case 'u': c = L'\u2524';
                        break; // right T
                    case 'v': c = L'\u2534';
                        break; // bottom T
                    case 'w': c = L'\u252c';
                        break; // top T
                    case 'x': c = L'\u2502';
                        break; // vertical bar
                }
                break;
            case cs_pc:
            {
                std::string ch(1, c);
                mPc850ToUcs4.reset();
                ucs4_string s = mPc850ToUcs4(ch);
                c = s[0];
                break;
            }
            case cs_normal:
                break;
        }
        mScreen.pushChar(c,mCurrentAttrs);
    }

    void CScreenStream::carriageReturn()
    {
    	KFM_LOG_DBG("carriage return");
        mScreen.setCursorCol(0);
    }

    void CScreenStream::lineFeed()
    {
    	KFM_LOG_DBG("line feed");
        mScreen.cursorDown();
        if (mCrlfMode)
        {
            mScreen.setCursorCol(0);
        }
    }

    void CScreenStream::backspace()
    {
    	KFM_LOG_DBG("backspace");
        mScreen.cursorLeft();
    }

    void CScreenStream::tab()
    {
    	KFM_LOG_DBG("tab");
        do
        {
            writeNormalChar(' ');
        }
        while (mScreen.getCursorCol() % 8);
    }

    void CScreenStream::reset()
    {
    	KFM_LOG_DBG("reset");
        mScreen.reset();
        mCurrentAttrs = Attributes();
        mSavedCursor = std::make_pair(0,0);
        mCharsetModes[0] = cs_normal;
        mCharsetModes[1] = cs_vt100gr;
        mCharsetMode = 0;
        mCrlfMode = false;
    }

    void CScreenStream::csiSGR()
    {
    	KFM_LOG_DBG("set char attributes");
        // Set attributes.  The new attributes are applied to the following characters.
        // Set attributes with no parameters means reset attributes to defaults.
        // Otherwise each parameter specifies a separate modification to the attributes.

        if (mNParams == 0)
        {
            mCurrentAttrs = Attributes();
            return;
        }

        for (int i = 0; i < mNParams; ++i)
        {
            switch (mParams[i])
            {
                case 0: mCurrentAttrs = Attributes();
                    break;
                case 1: mCurrentAttrs.bold = true;
                    break;
                case 2: mCurrentAttrs.halfbright = true;
                    break;
                case 4: mCurrentAttrs.underline = true;
                    break;
                case 5: mCurrentAttrs.blink = true;
                    break;
                case 7: mCurrentAttrs.inverse = true;
                    break;
                    //case 8:  current_attrs.invisible  = true;   break;  (vt100 has this, but not Linux)
                case 10: mCharsetModes[mCharsetMode] = cs_normal;
                    break;
                case 11: mCharsetModes[mCharsetMode] = cs_pc;
                    break;
                    //case 12: pc_charset = true; toggle_meta     break;
                case 21: mCurrentAttrs.bold = false;
                    break; // Hmm, not sure about these; both
                case 22: mCurrentAttrs.halfbright = false;
                    break; // are "set normal intensity".
                case 24: mCurrentAttrs.underline = false;
                    break;
                case 25: mCurrentAttrs.blink = false;
                    break;
                case 27: mCurrentAttrs.inverse = false;
                    break;
                    //case 28: current_attrs.invisible  = false;  break; (as above)
                case 38: mCurrentAttrs.underline = true;
                    mCurrentAttrs.fg = 7;
                    break;
                case 39: mCurrentAttrs.underline = false;
                    mCurrentAttrs.fg = 7;
                    break;
                case 49: mCurrentAttrs.bg = 0;
                    break;

                default: if (mParams[i] >= 30 && mParams[i] <= 37)
                    {
                        mCurrentAttrs.fg = mParams[i] - 30;
                    }
                    else if (mParams[i] >= 40 && mParams[i] <= 47)
                    {
                        mCurrentAttrs.bg = mParams[i] - 40;
                    }
                    else
                    {}
                    break;
            }
        }
    }

    void CScreenStream::csiSM()
    {
    	KFM_LOG_DBG("set modes");
        // Set modes.
        // Not implemented.
        if (mNParams != 1)
        {
            return;
        }

        switch (mParams[0])
        {
                //case 3: DECCRM mode - display control characters  break;
                //case 4: DECIM mode - insert mode                  break;
            case 20: mCrlfMode = true;
            break;
        }
    }

    void CScreenStream::csiRM()
    {
    	KFM_LOG_DBG("reset modes");
        // Reset modes.
        // These modes are not implemented, so resetting them does nothing.
        if (mNParams != 1)
        {
            return;
        }

        switch (mParams[0])
        {
            case 3: break; // DECCRM mode - display control characters
            case 4: break; // DECIM mode - insert mode
            case 20: mCrlfMode = false;
                break;
        }
    }

    void CScreenStream::csiDSR()
    {
    	KFM_LOG_DBG("report status");
        // Report status.
        // Not implemented.
        if (mNParams != 1)
        {
            return;
        }

        switch (mParams[0])
        {
                //case 5: DSR - device status - reply ESC [ 0 n  break;
                //case 6: CPR - cursor position - reply ESC [ y ; x R  break;
            default: 
            break;
        }
    }

    void CScreenStream::csiED()
    {
    	KFM_LOG_DBG("erase display");
        // Erase display.
        int start_row;
        int start_col;
        int end_row;
        int end_col;

        if (mNParams > 0 && mParams[0] == 1)
        {
            start_row = 0;
            start_col = 0;
            end_row = mScreen.getCursorRow();
            end_col = mScreen.getCursorCol();

        }
        else if (mNParams > 0 && mParams[0] == 2)
        {
            start_row = 0;
            start_col = 0;
            end_row = mScreen.numRows() - 1;
            end_col = mScreen.numCols() - 1;

        }
        else
        {
            start_row = mScreen.getCursorRow();
            start_col = mScreen.getCursorCol();
            end_row = mScreen.numRows() - 1;
            end_col = mScreen.numCols() - 1;
        }

        for (int r = start_row; r <= end_row; ++r)
        {
            for (int c = (r == start_row ? start_col : 0); c <= (r == end_row ? end_col : mScreen.numCols() - 1); ++c)
            {
                Cell &cell=mScreen.getCell(r,c);
                cell.c=L' ';
                cell.attrs=mCurrentAttrs;
            }
        }
    }

    void CScreenStream::csiCUP()
    {
    	KFM_LOG_DBG("cursor to absolute position");
        // Move cursor to absolute position.
        // With no parameters, move to origin.
        if (mNParams == 0)
        {
            mScreen.setCursor(0,0);
        }
        else
        {
            mScreen.setCursor(mParams[0] - 1,mParams[1] - 1);
        }
    }

    void CScreenStream::csiHVP()
    {
    	KFM_LOG_DBG("HVP");
        csiCUP();
    }

    void CScreenStream::csiCUU()
    {
    	KFM_LOG_DBG("cursor up to "<<mParams[0]);
        // Cursor Up.
        mScreen.cursorUp(mParams[0]);
    }

    void CScreenStream::csiCUD()
    {
    	KFM_LOG_DBG("cursor down to "<<mParams[0]);
        // Cursor Down.
        mScreen.cursorDown(mParams[0]);
    }

    void CScreenStream::csiVPR()
    {
    	KFM_LOG_DBG("VPR");
        csiCUD();
    }

    void CScreenStream::csiCUF()
    {
    	KFM_LOG_DBG("cursor forward right");
        // Cursor Forward (right).
        mScreen.cursorRight(mParams[0]);
    }

    void CScreenStream::csiHPR()
    {
    	KFM_LOG_DBG("HPR");
        csiCUF();
    }

    void CScreenStream::csiCUB()
    {
    	KFM_LOG_DBG("cursor back");
        // Cursor Back (left).
        mScreen.cursorLeft(mParams[0]);
    }

    void CScreenStream::csiCNL()
    {
    	KFM_LOG_DBG("cursor next line");
        // Cursor next line.
        csiCUD();
        mScreen.setCursorCol(0);
    }

    void CScreenStream::csiCPL()
    {
    	KFM_LOG_DBG("cursor previous line");
        // Cursor previous line.
        csiCUU();
        mScreen.setCursorCol(0);
    }

    void CScreenStream::csiCHA()
    {
    	KFM_LOG_DBG("cursor col "<<mParams[0]);
        mScreen.setCursorCol(mParams[0] - 1);
    }

    void CScreenStream::csiHPA()
    {
    	KFM_LOG_DBG("HPA");
        csiHPA();
    }

    void CScreenStream::csiVPA()
    {
    	KFM_LOG_DBG("set cursor row : "<<mParams[0]);
        mScreen.setCursorRow(mParams[0] - 1);
    }

    void CScreenStream::csiEL()
    {
    	KFM_LOG_DBG("erase line");
        // Erase line.
        int start;
        int end;

        if (mNParams > 0 && mParams[0] == 1)
        {
        	KFM_LOG_DBG("param = 1");
            start = 0;
            end = mScreen.getCursorCol();

        }
        else if (mNParams > 0 && mParams[0] == 2)
        {
        	KFM_LOG_DBG("param = 2");
            start = 0;
            end = mScreen.numCols() - 1;

        }
        else
        {
        	KFM_LOG_DBG("no param or unkown value : num params = "<<mNParams<<" param="<<mParams[0]);
            start = mScreen.getCursorCol();
            end = mScreen.numCols() - 1;
        }
        KFM_LOG_DBG("start = "<<start<<" end="<<end);
        for (int i = start; i <= end; ++i)
        {
            Cell & cell=mScreen.getCell(mScreen.getCursorRow(),i);
            cell.c=L' ';
            cell.attrs=mCurrentAttrs;
        }
    }

    void CScreenStream::csiICH()
    {
    	KFM_LOG_DBG("insert blanks, param="<<mParams[0]);
        // Insert blanks.
        int n = mParams[0];
        for (int i = mScreen.numCols() - 1; i >= mScreen.getCursorCol() + n; --i)
        {
            mScreen.getCell(mScreen.getCursorRow(), i) = mScreen.getCell(mScreen.getCursorRow(), i - n);
        }
        for (int i = mScreen.getCursorCol(); i < mScreen.getCursorCol() + n; ++i)
        {
            Cell & cell = mScreen.getCell(mScreen.getCursorRow(),i);
            cell.c=L' ';
            cell.attrs=mCurrentAttrs;
        }
    }

    void CScreenStream::csiDCH()
    {
    	KFM_LOG_DBG("delete characters param="<<mParams[0]);
        // Delete Characters.
        int n = mParams[0];
        for (int i = mScreen.getCursorCol(); i < mScreen.numCols() - n; ++i)
        {
            mScreen.getCell(mScreen.getCursorRow(), i) = mScreen.getCell(mScreen.getCursorRow(), i + n);
        }
        for (int i = mScreen.numCols() - n; i < mScreen.numCols(); ++i)
        {
            Cell & cell=mScreen.getCell(mScreen.getCursorRow(),i);
            cell.c=L' ';
            cell.attrs=mCurrentAttrs;
        }
    }

    void CScreenStream::csiIL()
    {
    	KFM_LOG_DBG("insert line, param="<<mParams[0]);
        // Insert Line.
        int n = mParams[0];
        mScreen.scrollUp(n);
    }

    void CScreenStream::csiDL()
    {
    	KFM_LOG_DBG("delete line, param="<<mParams[0]);
        // Delete Line.
        int n = mParams[0];
        mScreen.scrollDown( n);
    }

    void CScreenStream::csiECH()
    {
        // Erase characters.
        int n = mParams[0];
        KFM_LOG_DBG("erase characters, param="<<n);
        for (int i = mScreen.getCursorCol(); i < mScreen.getCursorCol() + n && i < mScreen.numCols(); ++i)
        {
            Cell &cell=mScreen.getCell(mScreen.getCursorRow(),i);
            cell.c=L' ';
            cell.attrs=mCurrentAttrs;
        }
    }

    void CScreenStream::csiDECSTBM()
    {
        // Set scrolling region.
        int newtop;
        int newbottom;
        KFM_LOG_DBG("set scrolling region");
        if (mNParams == 0)
        {
        	KFM_LOG_DBG("no param given");
            newtop = 0;
            newbottom = mScreen.numRows() - 1;

        }
        else if (mNParams < 2)
        {
        	KFM_LOG_DBG("not correct parameters, droping request ");
            return;

        }
        else
        {
            newtop = mParams[0] - 1;
            newbottom = mParams[1] - 1;
        }
        KFM_LOG_DBG("top: "<<newtop<<" bottom="<<newbottom);
        mScreen.setScrollingRegion(newtop, newbottom);

    }

    void CScreenStream::csiSAVECUR()
    {
        // Save cursor position.
        mSavedCursor= mScreen.getCursor();
        KFM_LOG_DBG("save cursor position , cursor saved {row:"<<mSavedCursor.first<<",col:"<<mSavedCursor.second<<"}");
    }

    void CScreenStream::csiRESTORECUR()
    {
    	KFM_LOG_DBG("restore cursor position, saved cursor {row:"<<mSavedCursor.first<<",col:"<<mSavedCursor.second<<"}");
        // Restore cursor position.
        mScreen.setCursor(mSavedCursor.first,mSavedCursor.second);
    }

    void CScreenStream::csiDECSET()
    {
    	KFM_LOG_DBG("DECSET ");
        if (mNParams != 1)
        {
        	KFM_LOG_DBG("not correct params, droping ");
            return;
        }

        switch (mParams[0])
        {
                //case 1:    Change cursor key prefix    break;
                //case 3:    80/132-column mode          break;
                //case 5:    Reverse video mode          break;
                //case 6:    Scroll-region-relative cursor addressing mode  break;
                //case 7:    Autowrap mode               break; [*]
                //case 8:    Autorepeat                  break;
                //case 9:    X10 mouse reporting         break;
            case 25: mScreen.setCursorVisible(true);
                break;
                //case 1000: X11 mouse reporting         break;
            default:
                break;
        }
    }

void CScreenStream::csiDECRST()
{
	KFM_LOG_DBG("DECRST");
    if (mNParams != 1)
    {
    	KFM_LOG_DBG("not correct params, droping");
        return;
    }

    switch (mParams[0])
    {
            //case 1:    Change cursor key prefix     break;
            //case 3:    80/132-column mode           break;
            //case 5:    Reverse video mode           break;
            //case 6:    Scroll-region-relative cursor addressing mode  break;
            //case 7:    Autowrap mode                break;
            //case 8:    Autorepeat                   break;
            //case 9:    X10 mouse reporting          break;
        case 25: mScreen.setCursorVisible(false);
            break;
            //case 1000: X11 mouse reporting          break;
        default:
            break;
    }
}

void CScreenStream::writeChar(ucs4_char c)
{
	KFM_LOG_DBG("writting char, c="<<(char)c);
    if (c <= 31)
    {
    	KFM_LOG_DBG(" char <= 31");
        switch (c)
        {
            case '\a': /* bell */ break;
            case '\b': backspace();
                break;
            case '\t': tab();
                break;
            case '\n': /* fall through */
            case '\v': /* fall through */
            case '\f': lineFeed();
                break;
            case '\r': carriageReturn();
                break;
            case '\x0E': mCharsetMode = 1;
                break;
            case '\x0F': mCharsetMode = 0;
                break;
            case '\x18': /* fall through */
            case '\x1A': mEscState = normal;
                break;
            case '\x1B': mEscState = seen_esc;
                break;
            default: 
                break;
        }

    }
    else if (c == 0x9b)
    {
    	KFM_LOG_DBG("c == 0x9b");
        // Is there a conflict between 9b==CSI and a UTF8 or ISO-8859 interpretation?
        mEscState = seen_csi;
        mNParams = 0;
        mParams[0] = 1;

    }
    else
    {
    	KFM_LOG_DBG("char > 31");
        switch (mEscState)
        {
            case normal:
            	KFM_LOG_DBG("normal char");
                writeNormalChar(c);
                break;

            case seen_esc:
                switch (c)
                {
                    case 'c':
                    	KFM_LOG_DBG("reset");
                    	reset();
                        mEscState = normal;
                        break;
                    case 'D':
                    	KFM_LOG_DBG("line feed");
                    	lineFeed();
                        mEscState = normal;
                        break;
                    case 'E':
                    	KFM_LOG_DBG("carriage return");
                    	carriageReturn();
                        mEscState = normal;
                        break;
                        //case 'H': set_tab_stop();                esc_state=normal; break; [*]
                    case 'M':
                    	KFM_LOG_DBG("cursor up");
                    	mScreen.cursorUp();
                        mEscState = normal;
                        break;
                        //case 'Z': dec_priv_ident();              esc_state=normal; break; // kernel returns ESC [ ? 6 c
                        //case '7': save_state();                  esc_state=normal; break; // save cursor pos, attributes, charsets
                        //case '8': restore_state();   dirty=true; esc_state=normal; break;
                    case '[':
                    	KFM_LOG_DBG("[");
                    	mEscState = seen_csi;
                        mNParams = 0;
                        mParams[0] = 1;
                        break;
                        //case '%':                                esc_state=seen_escpercent; break;  // select character set based on next char
                        // @=8859-1, G=8=UTF-8
                        //case '#':                                esc_state=seen_eschash; break;     // ESC # 8 = fill screen with Es
                    case '(':
                    	KFM_LOG_DBG("(");
                    	mEscState = seen_esclparen;
                        break; // select G0 charset based on next char
                    case ')':
                    	KFM_LOG_DBG(")");
                    	mEscState = seen_escrparen;
                        break; // select G1 charset based on next char
                        //case '>': numeric_keypad_mode();         esc_state=normal; break;
                        //case '=': application_keypad_mode();     esc_state=normal; break;
                        //case ']':                                esc_state=seen_escrbraket; break;
                        // ESC ] P nrrggbb = set palette; colour n (hex)
                        // ESC ] R = reset palette [*]
                    default: 
                        mEscState = normal;
                }
                break;

            case seen_csi: /* fall through */
            case seen_csi_private:
            	KFM_LOG_DBG("csi_private");
                if (c >= '0' && c <= '9')
                {
                    if (mNParams == 0)
                    {
                        mNParams = 1;
                        mParams[0] = 0;
                    }
                    mParams[mNParams - 1] = mParams[mNParams - 1] * 10 + (c - '0');

                }
                else if (c == ';')
                {
                    if (mNParams >= nparams_max)
                    {
                        return;
                    }
                    mNParams++;
                    mParams[mNParams - 1] = 0;

                }
                else if (c == '?')
                {
                    mEscState = seen_csi_private;

                }
                else
                {
                    if (mEscState == seen_csi_private)
                    {
                        switch (c)
                        {
                                //case 'c': Unknown; code seen but not described in 'man console_codes' [*]
                            case 'h': csiDECSET();
                                break;
                            case 'l': csiDECRST();
                                break;
                            default: 
                                break;
                        }
                    }
                    else
                    {
                        switch (c)
                        {
                            case '@': csiICH();
                                break;
                            case 'A': csiCUU();
                                break;
                            case 'B': csiCUD();
                                break;
                            case 'C': csiCUF();
                                break;
                            case 'D': csiCUB();
                                break;
                            case 'E': csiCNL();
                                break;
                            case 'F': csiCPL();
                                break;
                            case 'G': csiCHA();
                                break;
                            case 'H': csiCUP();
                                break;
                            case 'J': csiED();
                                break;
                            case 'K': csiEL();
                                break;
                            case 'L': csiIL();
                                break;
                            case 'M': csiDL();
                                break;
                            case 'P': csiDCH();
                                break;
                            case 'X': csiECH();
                                break;
                            case 'a': csiHPR();
                                break;
                                //case 'c': csi_DA();  break;  // Reply ESC [ ? 6 c
                            case 'd': csiVPA();
                                break;
                            case 'e': csiVPR();
                                break;
                            case 'f': csiHVP();
                                break;
                                //case 'g': csi_TBC(); break;  // Clear tab stop [*]
                            case 'h': csiSM();
                                break;
                            case 'l': csiRM();
                                break;
                            case 'm': csiSGR();
                                break;
                            case 'n': csiDSR();
                                break;
                                //case 'q': csi_DECLL(); break; // Set keyboard LEDs
                            case 'r': csiDECSTBM();
                                break;
                            case 's': csiSAVECUR();
                                break;
                            case 'u': csiRESTORECUR();
                                break;
                            case '`': csiHPA();
                                break;
                            default: 
                                break;
                        }
                    }

                    mEscState = normal;

                }
                break;

            case seen_esclparen: /* fall through */
            case seen_escrparen:
            {
            	KFM_LOG_DBG("escrparen");
                charset_mode_t m = cs_normal;
                switch (c)
                {
                    case 'B': m = cs_normal;
                        break;
                    case '0': m = cs_vt100gr;
                        break;
                    case 'U': m = cs_pc;
                        break;
                }
                if (mEscState == seen_esclparen)
                {
                    mCharsetModes[0] = m;
                }
                else
                {
                    mCharsetModes[1] = m;
                }
                mEscState = normal;
                break;
            }
        }
    }
}

void CScreenStream::write(ucs4_string & data)
{
    for (size_t i = 0; i < data.length(); ++i)
    {
        writeChar(data[i]);
    }
}

CScreenStream & CScreenStream::operator <<(ucs4_string& data)
{
    write(data);
    return *this;
}



}} //end of namespace KFM::CScreenStream
