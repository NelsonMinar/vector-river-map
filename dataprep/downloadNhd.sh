#!/bin/bash

# Shell script to download NHDPlus data
# Primary source is http://www.horizon-systems.com/NHDPlus/NHDPlusV2_data.php
# When complete, the result will be NNN MB of .7z archives,
# NNN MB of NHDFlowline.*, and NNN MB of PlusFlowlineVAA.dbf files

# The p7zip archiver is required; available via homebrew, apt, or from
# the source at http://www.7-zip.org/download.html

set -eu

DESTDIR=./NHD
# If you want to do a test run for California only, set this to true
CAONLY=true

# URLs of data, painstakingly copied out of the web page. Could automate with a scraper
URLS=`cat << EOF
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusCA/NHDPlusV21_CA_18_NHDSnapshot_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusCA/NHDPlusV21_CA_18_NHDPlusAttributes_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusPN/NHDPlusV21_PN_17_NHDSnapshot_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusPN/NHDPlusV21_PN_17_NHDPlusAttributes_05.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusGB/NHDPlusV21_GB_16_NHDSnapshot_05.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusGB/NHDPlusV21_GB_16_NHDPlusAttributes_02.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusCO/NHDPlus15/NHDPlusV21_CO_15_NHDSnapshot_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusCO/NHDPlus15/NHDPlusV21_CO_15_NHDPlusAttributes_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusCO/NHDPlus14/NHDPlusV21_CO_14_NHDSnapshot_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusCO/NHDPlus14/NHDPlusV21_CO_14_NHDPlusAttributes_05.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusRG/NHDPlusV21_RG_13_NHDSnapshot_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusRG/NHDPlusV21_RG_13_NHDPlusAttributes_02.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusTX/NHDPlusV21_TX_12_NHDSnapshot_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusTX/NHDPlusV21_TX_12_NHDPlusAttributes_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus11/NHDPlusV21_MS_11_NHDSnapshot_05.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus11/NHDPlusV21_MS_11_NHDPlusAttributes_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus10L/NHDPlusV21_MS_10L_NHDSnapshot_05.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus10L/NHDPlusV21_MS_10L_NHDPlusAttributes_08.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus10U/NHDPlusV21_MS_10U_NHDSnapshot_06.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus10U/NHDPlusV21_MS_10U_NHDPlusAttributes_06.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusSR/NHDPlusV21_SR_09_NHDSnapshot_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusSR/NHDPlusV21_SR_09_NHDPlusAttributes_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus08/NHDPlusV21_MS_08_NHDSnapshot_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus08/NHDPlusV21_MS_08_NHDPlusAttributes_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus07/NHDPlusV21_MS_07_NHDSnapshot_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus07/NHDPlusV21_MS_07_NHDPlusAttributes_06.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus06/NHDPlusV21_MS_06_NHDSnapshot_06.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus06/NHDPlusV21_MS_06_NHDPlusAttributes_06.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus05/NHDPlusV21_MS_05_NHDSnapshot_05.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMS/NHDPlus05/NHDPlusV21_MS_05_NHDPlusAttributes_04.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusGL/NHDPlusV21_GL_04_NHDSnapshot_07.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusGL/NHDPlusV21_GL_04_NHDPlusAttributes_08.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusSA/NHDPlus03W/NHDPlusV21_SA_03W_NHDSnapshot_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusSA/NHDPlus03W/NHDPlusV21_SA_03W_NHDPlusAttributes_02.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusSA/NHDPlus03S/NHDPlusV21_SA_03S_NHDSnapshot_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusSA/NHDPlus03S/NHDPlusV21_SA_03S_NHDPlusAttributes_02.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusSA/NHDPlus03N/NHDPlusV21_SA_03N_NHDSnapshot_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusSA/NHDPlus03N/NHDPlusV21_SA_03N_NHDPlusAttributes_02.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMA/NHDPlusV21_MA_02_NHDSnapshot_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusMA/NHDPlusV21_MA_02_NHDPlusAttributes_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusNE/NHDPlusV21_NE_01_NHDSnapshot_03.7z
http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusNE/NHDPlusV21_NE_01_NHDPlusAttributes_03.7z
EOF`

# Override URLS to a shorter list if just doing California
if [ "$CAONLY" == "true" ]; then
    URLS="http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusCA/NHDPlusV21_CA_18_NHDSnapshot_04.7z http://www.horizon-systems.com/NHDPlusData/NHDPlusV21/Data/NHDPlusCA/NHDPlusV21_CA_18_NHDPlusAttributes_03.7z"
fi

# Set up the destination directory
mkdir -p $DESTDIR
cd $DESTDIR

# Fetch all the URLs
for url in $URLS; do
    out=`basename $url`
    if [ -e "$out" ]; then
        echo "Already have $out"
    else
        echo "Fetching $out"
        curl -f -# --retry 2 --output "$out-tmp" "$url" && mv "$out-tmp" "$out"
        chmod -w "$out"
    fi
done

echo "All files downloaded; extracting NHDFlowline and PlusFlowlineVAA"

# Extract the datafiles we need from the downloads. Would be nice to only do this if they don't exist
for nhd in *NHDSnapshot*7z; do
    7z -y x "$nhd" '*/*/NHDSnapshot/Hydrography/NHDFlowline*' '*/*/NHDSnapshot/Hydrography/nhdflowline*' | grep Extracting || true
done
for vaa in *NHDPlusAttributes*7z; do
    7z -y x "$vaa" '*/*/NHDPlusAttributes/PlusFlowlineVAA.dbf' | grep Extracting || true
done

echo
echo -n "Size of downloaded archives: "
du -chs *7z | awk '/total/ { print $1 }'
echo -n "Size of extracted data files: "
du -chs NHDPlus??  | awk '/total/ { print $1 }'
