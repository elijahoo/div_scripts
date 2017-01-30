#!/bin/bash -e
# This script is renewing the certificate for the IOS-App.
# Renew if "apple-app-site-association" is older than the key or the certificate
# Created at 30.01.2017 Elias Häfliger
#

home_dir=/home/swissfmc
json=$home_dir/public_html/polr/public/.well-known/unsigned.json
apple_file=$home_dir/public_html/polr/public/.well-known/apple-app-site-association
keys=$home_dir/ssl/keys/
certificates=$home_dir/ssl/certs/

apple_file_timestamp=0    # needed, if apple_file not yet existing

pre_name="chfm_ch_"       # first char's of certificate till beginning of keyname

#################
### FUNCTIONS ###
#################

function get_filename()
# get the name of the latest file
# param: filename incl. path
{
  filename=`ls -1t $1 | head -n 1`

  echo "$filename"
}

function get_sub_12()
# get first 12 characters from position X
# params: string, position (nth char)
{
  chrlen=${#2}
  sub_12=${1:${chrlen}:12}

  echo "$sub_12"
}

function get_timestamp()
# get timestamp in seconds
# param: filename incl. path
{
  timestamp=`stat -c %Y $1`

  echo "$timestamp"
}

function run_command()
# runs the final command for renewing apple certificate
# params: json, apple_file, key, cert
{
  openssl smime -sign -nodetach -in "$1" -out "$2" -outform DER -inkey $3 -signer $4
}

###############
### PROGRAM ###
###############

# be sure, that all the needed files exist
if [ -f $json ]; then
  if [ "$(ls -A ${certificates}${pre_name}*.crt)" ]; then
    # get the current certificate file
    cert_name=$( get_filename "${certificates}${pre_name}*.crt" )
    cert_basename=$( basename $cert_name)
    cert_name_12=$( get_sub_12 $cert_basename $pre_name)
    # get its timestamp
    cert_timestamp=$( get_timestamp $cert_name )

    if [ "$(ls -A ${keys}${cert_name_12}*)" ]; then
      key_name=$( get_filename "${keys}${cert_name_12}*" )
      key_timestamp=$( get_timestamp $key_name )

      if [ -f $apple_file ]; then
        # Get informations of each File
        apple_file_timestamp=$( get_timestamp $apple_file )
      fi

      # Here we begin with the logical things...
      # Create if not existing or if older than key or older than certificate
      if [ ! -f $apple_file ] || [ $key_timestamp -gt $apple_file_timestamp ] || [ $cert_timestamp -gt $apple_file_timestamp ]; then

        run_command $json $apple_file $key_name $cert_name
        echo "Apple Zertifikat wurde erneuert!"
      fi
    else
      echo "Key missing! ABORT"
      exit 1
    fi
  else
    echo "Certificate missing! ABORT"
    exit 1
  fi
else
  echo "Json missing! ABORT"
  exit 1
fi
