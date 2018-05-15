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
  echo "  <FileSize type=\"integer\">"$(stat --printf="%s" $OUT/${version}.zip)"</FileSize>"
  echo "  <Developer>$MAINTAINER</Developer>"
  echo "  <WebsiteURL nil=\"true\">cosmic-os.org</WebsiteURL>"
  echo "  <DonateURL>paypal.me/CosmicOS</DonateURL>"
  echo "  <Changelog>$CHANGELOG</Changelog>"
  echo "</ROM>"
}
function upload_file() {
  if [[ "$COS_RELEASE" == true ]]; then
	if [[ "$device" == temp ]]; then
		MAINTAINER=Maintainer Name
		parent=1tH5a1-daZr_ZpopJhpg5ObAL4HEZaVn6
		fileid=$(gdrive upload --parent $parent $(OUT_DIR_COMMON_BASE)/*/target/product/$device/"Cosmic-OS"*$device*".zip" | tail -1 | awk '{print $2}')
		update_target()
	fi
  else
    echo "Device is not official."
  fi
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
      printf 'Enter HTTP / HTTPS URL: '
      read -r url
    else
      durl="https://drive.google.com/uc?export=download&id=$fileid"
      url="https://drive.google.com/file/d/$fileid/view"
    fi
    version=$(echo $version | sed -e "s/${version_date}/${date}/g")
    cd $(gettop)/vendor/ota
    git reset --hard HEAD
    git pull cosmic-os oreo-mr1
    mkdir -p $(gettop)/vendor/ota/changelogs
    touch $(gettop)/vendor/ota/changelogs/${version}.txt
    head -n 45 $OUT/cos_${device}-Changelog.txt > $(gettop)/vendor/ota/changelogs/${version}.txt
    editor $(gettop)/vendor/ota/changelogs/${version}.txt

    CHANGELOG="$(cat $(gettop)/vendor/ota/changelogs/${version}.txt)"
    
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
