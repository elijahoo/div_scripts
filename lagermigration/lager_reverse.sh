#!/bin/bash
cd /sfmtool/prg/
tar xvzf ./exp/artaswgrd.tgz
tar xvzf ./exp/artikel.tgz
tar xvzf ./exp/benutzer.tgz
tar xvzf ./exp/fmkvrbzhl.tgz
tar xvzf ./exp/fremdsys.tgz
tar xvzf ./exp/ihauftr.tgz
tar xvzf ./exp/ihaufwnd.tgz
tar xvzf ./exp/lgrausw.tgz
tar xvzf ./exp/lgrbstnd.tgz
tar xvzf ./exp/lgrhist.tgz
tar xvzf ./exp/lgrmbok.tgz
tar xvzf ./exp/lgrmbst.tgz
tar xvzf ./exp/lgrplan.tgz
tar xvzf ./exp/vorgang.tgz
cp def.bak/*.def def/

rm -f exp/*.txt
rm -f exp/*.tmp
