/* 
 * File:   screen_stream.hpp
 * Author: vic
 *
 * Created on January 5, 2012, 2:28 PM
 */

#ifndef SCREEN_STREAM_HPP
#define	SCREEN_STREAM_HPP

#include <string>

#include "Cell.hh"
#include "Attributes.hh"
#include "screen.hpp"
#include "unicode.hh"
#include "Iconver.hh"

namespace KFM{namespace Terminal{

    class CScreenStream
    {
        
    public:
        
        CScreenStream(CScreen &screen);
        ~CScreenStream();
        void write(ucs4_string &data);
        void writeChar(ucs4_char c);
        CScreenStream & operator << (ucs4_string &data);
        CScreen & getScreen();
    private:
        
        CScreen  &mScreen;
        Attributes mCurrentAttrs;
        std::pair<size_t,size_t> mSavedCursor;
        enum charset_mode_t { cs_normal, cs_pc, cs_vt100gr };
        charset_mode_t mCharsetModes[2];
        int mCharsetMode;
        bool mCrlfMode;
        int mNParams;
        static const int nparams_max = 16;
        int mParams[nparams_max];
        enum esc_state_t { normal, seen_esc, seen_csi, seen_csi_private, seen_esclparen, seen_escrparen };
        esc_state_t mEscState;
        pbe::Iconver<pbe::permissive,char,ucs4_char> mPc850ToUcs4;
        
    protected:
        void writeNormalChar(ucs4_char c);
        void carriageReturn();
        void lineFeed();
        void backspace();
        void tab();
        void reset();
        void csiSGR();
        void csiSM();
        void csiRM();
        void csiDSR();
        void csiED();
        void csiCUP();
        void csiHVP();
        void csiCUU();
        void csiCUD();
        void csiVPR();
        void csiCUF();
        void csiHPR();
        void csiCUB();
        void csiCNL();
        void csiCPL();
        void csiCHA();
        void csiHPA();
        void csiVPA();
        void csiEL();
        void csiICH();
        void csiDCH();
        void csiIL();
        void csiDL();
        void csiECH();
        void csiDECSTBM();
        void csiSAVECUR();
        void csiRESTORECUR();
        void csiDECSET();
        void csiDECRST();
    };

}} //end of namespace KFM::Terminal

#endif	/* SCREEN_STREAM_HPP */

