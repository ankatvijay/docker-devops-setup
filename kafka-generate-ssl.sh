#!/usr/bin/env bash

set -eu

PREFIX=$1
ROOT_CA_FILE='root-ca.pem'
ROOT_CA_KEY_FILE='root-ca-key.pem'
TRUSTSTORE_WORKING_DIRECTORY='truststore'
KEYSTORE_WORKING_DIRECTORY='keystore'
KEYSTORE_FILENAME=$PREFIX'-kafka-keystore.jks'
TRUSTSTORE_FILENAME=$PREFIX'-kafka-truststore.jks'
VALIDITY_IN_DAYS=3650
KEYSTORE_SIGN_REQUEST='keystore-sign-req'
ROOT_SIGN_REQUEST_SRL='root-ca.srl'
KEYSTORE_SIGNED_CERT='keystore-signed-cert'

COUNTRY='COUNTRY_NAME'
STATE='STATE_NAME'
OU='ORGANIZATION_UNIT_NAME'
CN=`hostname -f`
LOCATION='LOCATION_NAME'
PASS='Password'

echo "Deleting old files if they exist..."
echo "Print Prefix: $PREFIX"

rm -rf $TRUSTSTORE_WORKING_DIRECTORY/$TRUSTSTORE_FILENAME $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME

function file_exists_and_exit() {
  echo "'$1' cannot exist. Move or delete it before"
  echo "re-running this script."
  exit 1
}

if [ -e "$PREFIX" ]; then
  file_exists_and_exit $PREFIX
fi

if [ ! -e "$TRUSTSTORE_WORKING_DIRECTORY" ]; then
  mkdir $TRUSTSTORE_WORKING_DIRECTORY
fi

if [ ! -e "$KEYSTORE_WORKING_DIRECTORY" ]; then
  mkdir $KEYSTORE_WORKING_DIRECTORY
fi

if [ ! -e "$ROOT_CA_KEY_FILE" ]; then
  openssl genrsa -aes256 -out $ROOT_CA_KEY_FILE 4096
fi

if [ ! -e "$ROOT_CA_FILE" ]; then
  openssl req -new -x509 -sha256 -days $VALIDITY_IN_DAYS -key $ROOT_CA_KEY_FILE -out $ROOT_CA_FILE
fi

if [ -e "$KEYSTORE_SIGN_REQUEST" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST
fi

if [ -e "$ROOT_SIGN_REQUEST_SRL" ]; then
  file_exists_and_exit $ROOT_SIGN_REQUEST_SRL
fi

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi

echo "Welcome to the Kafka SSL keystore and trust store generator script."

trust_store_file=""
key_store_file=""

echo
echo "OK, we'll skip generating a root ca and associated private key."
echo
echo "First, the private key."
echo

#openssl req -new -x509 -sha256 -keyout $TRUSTSTORE_WORKING_DIRECTORY/root-ca-key.pem \
#  -out $TRUSTSTORE_WORKING_DIRECTORY/ca-cert -days $VALIDITY_IN_DAYS -nodes \
#  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=$CN"

echo
echo "Two files were created:"
echo " - $ROOT_CA_KEY_FILE -- the private key used later to"
echo "   sign certificates"
echo " - $ROOT_CA_FILE -- the certificate that will be"
echo "   stored in the trust store in a moment and serve as the certificate"
echo "   authority (CA). Once this certificate has been stored in the trust"
echo "   store, it will be deleted. It can be retrieved from the trust store via:"
echo "   $ keytool -keystore <trust-store-file> -export -alias CARoot -rfc"

openssl x509 -in $ROOT_CA_FILE -purpose -noout -text

echo
echo "Now the trust store will be generated from the certificate."
echo

keytool -keystore $TRUSTSTORE_WORKING_DIRECTORY/$TRUSTSTORE_FILENAME \
  -alias CARoot -import -file $ROOT_CA_FILE \
  -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" \
  -keypass $PASS -storepass $PASS -storetype JKS

trust_store_file="$TRUSTSTORE_WORKING_DIRECTORY/$TRUSTSTORE_FILENAME"

echo
echo "$TRUSTSTORE_WORKING_DIRECTORY/$TRUSTSTORE_FILENAME was created."

echo
echo "Continuing with:"
echo " - trust store file:        $trust_store_file"

keytool -list -v -keystore $trust_store_file -storepass $PASS -keypass $PASS -noprompt


echo
echo "Now, a keystore will be generated. Each broker and logical client needs its own"
echo "keystore. This script will create only one keystore. Run this script multiple"
echo "times for multiple keystores."
echo
echo "     NOTE: currently in Kafka, the Common Name (CN) does not need to be the FQDN of"
echo "           this host. However, at some point, this may change. As such, make the CN"
echo "           the FQDN. Some operating systems call the CN prompt 'first / last name'"

# To learn more about CNs and FQDNs, read:
# https://docs.oracle.com/javase/7/docs/api/javax/net/ssl/X509ExtendedTrustManager.html

keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME \
  -alias $PREFIX -validity $VALIDITY_IN_DAYS -genkey -keyalg RSA \
  -keysize 4096 -ext SAN=DNS:$PREFIX,DNS:127.0.0.1,DNS:*.test.com,IP:0.0.0.0,IP:127.0.0.1,EMAIL:test@test.com \
  -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" \
  -keypass $PASS -storepass $PASS -storetype JKS


key_store_file="$KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME"

echo
echo "'$KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME' now contains a key pair and a"
echo "self-signed certificate. Again, this keystore can only be used for one broker or"
echo "one logical client. Other brokers or clients need to generate their own keystores."

keytool -list -v -keystore $key_store_file -storepass $PASS -keypass $PASS -noprompt

echo
echo "Fetching the certificate from the trust store and storing in $ROOT_CA_FILE."
echo

keytool -keystore $trust_store_file -export -alias CARoot -rfc -file $ROOT_CA_FILE -keypass $PASS -storepass $PASS

keytool -list -v -keystore $trust_store_file -storepass $PASS -keypass $PASS -noprompt

echo
echo "Now a certificate signing request will be made to the keystore."
echo
keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias $PREFIX \
  -certreq -file $KEYSTORE_SIGN_REQUEST -keypass $PASS -storepass $PASS

echo
echo "Now the trust store's private key (CA) will sign the keystore's certificate."
echo
openssl x509 -req -sha256 -CA $ROOT_CA_FILE -CAkey $ROOT_CA_KEY_FILE \
  -in $KEYSTORE_SIGN_REQUEST -out $KEYSTORE_SIGNED_CERT \
  -days $VALIDITY_IN_DAYS -CAcreateserial -passin pass:$PASS
# creates $ROOT_SIGN_REQUEST_SRL which is never used or needed.

echo
echo "Now the CA will be imported into the keystore."
echo
keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias CARoot \
  -import -file $ROOT_CA_FILE -keypass $PASS -storepass $PASS -noprompt

echo
echo "Now the keystore's signed certificate will be imported back into the keystore."
echo
keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias $PREFIX -import \
  -file $KEYSTORE_SIGNED_CERT -keypass $PASS -storepass $PASS

echo
echo "All done!"
echo
echo "Deleting intermediate files. They are:"
echo " - '$ROOT_SIGN_REQUEST_SRL': CA serial number"
echo " - '$KEYSTORE_SIGN_REQUEST': the keystore's certificate signing request"
echo "   (that was fulfilled)"
echo " - '$KEYSTORE_SIGNED_CERT': the keystore's certificate, signed by the CA, and stored back"
echo "    into the keystore"

rm $ROOT_SIGN_REQUEST_SRL
rm $KEYSTORE_SIGN_REQUEST
rm $KEYSTORE_SIGNED_CERT

