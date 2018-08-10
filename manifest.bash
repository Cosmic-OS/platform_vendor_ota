#!/bin/bash

function write_xml() {
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  echo "<ROM>"
  echo "  <RomName>$product</RomName>"
  echo "  <VersionName><![CDATA[ $version ]]></VersionName>"
  echo "  <VersionNumber type=\"integer\">"${date}"</VersionNumber>"
  echo "  <DirectUrl>$durl</DirectUrl>"
  echo "  <HttpUrl>$url</HttpUrl>"
  echo "  <Android>$android</Android>"
  echo "  <CheckMD5>"$(md5sum $OUT/$version.zip | awk '{print $1}')"</CheckMD5>"
  echo "  <SHA256>"$(sha256 $OUT/$version.zip | awk '{print $2}')"</SHA256>"
  echo "  <FileSize type=\"integer\">"$(stat --printf="%s" $OUT/${version}.zip)"</FileSize>"
  echo "  <Developer>$MAINTAINER</Developer>"
  echo "  <WebsiteURL nil=\"true\">cosmic-os.org</WebsiteURL>"
  echo "  <DonateURL>paypal.me/CosmicOS</DonateURL>"
  echo "  <Changelog>$CHANGELOG</Changelog>"
  echo "</ROM>"
}

function update_target() {
  if [[ "$COS_RELEASE" == true ]]; then

    for var in "$@"
    do
      if [[ "$var" == "-d" ]]; then
        CUSTOM_DATE=true
      elif [[ "$var" == "-u" ]]; then
        CUSTOM_URL=true
      fi
    done
    version="$COS_VERSION"
    version_date=$(echo $version | rev | cut -d _ -f 2 | rev)
    device=$(echo $TARGET_PRODUCT | cut -d _ -f 2,3)
    android="8.1.0"
    product=Cosmic-OS_${device}_${android}
    if [[ "$CUSTOM_DATE" == true ]]; then
      printf 'Enter date in format YYYYMMDD: '
      read -r mdate
      date=$(date -d "$mdate" +'%Y%m%d'); 
    else
      date=$(date +%Y%m%d)
    fi
    if [[ "$CUSTOM_URL" == true ]]; then
      printf 'Enter Direct URL: '
      read -r durl
      printf 'Enter HTTP URL: '
      read -r url
    else
      durl="https://downloads.sourceforge.net/project/cosmic-os/$device/${version}.zip"
      url="https://sourceforge.net/projects/cosmic-os/files/$device"
    fi
    version=$(echo $version | sed -e "s/${version_date}/${date}/g")
    cd $(gettop)/vendor/ota
    git reset --hard HEAD
    git pull cosmic-os pulsar-release
    mkdir -p $(gettop)/vendor/ota/changelogs
    touch $(gettop)/vendor/ota/changelogs/${version}.txt
    head -n 45 $OUT/cos_${device}-Changelog.txt > $(gettop)/vendor/ota/changelogs/${version}.txt
    editor $(gettop)/vendor/ota/changelogs/${version}.txt

    CHANGELOG="$(cat $(gettop)/vendor/ota/changelogs/${version}.txt)"

    if [[ -z "$MAINTAINER" ]]; then
      echo "Who are you?"
      read MAINTAINER
      echo "Hello ${MAINTAINER}!"
    fi
    
    write_xml > $device.xml
    git add -A
    git commit -m "OTA: Update $device ($(date -d "$mdate" +'%d/%m/%Y'))"
    echo
    if [[ "$COS_BIWEEKLY" == true ]]; then
      git push https://${GUSER}:${GPASS}@github.com/${GREPO} -f
    else
      echo "Please push the commit and open a PR."
    fi
  else
    echo "Device is not official."
  fi
}
