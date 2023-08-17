#!/bin/bash

# SSL_ENABLE
# SSL_DOMAIN
# SSL_PASSWORD
# SSL_MAIL

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
}
log_w() {
    log
    printf "\033[0;35m [WARN] --- %s \033[0m\n" "${@}"
}
log_e() {
    log
    printf "\033[0;31m [ERROR]  --- %s \033[0m\n" "${@}"
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

if [ -z "$SSL_DOMAIN" ]; then
    log_e "Variable SSL_DOMAIN is empty."
    exit 1
fi
if [ -z "$SSL_PASSWORD" ]; then
    log_e "Variable SSL_PASSWORD is empty."
    exit 1
fi
if [ -z "$SSL_MAIL" ]; then
    log_e "Variable SSL_MAIL is empty."
    exit 1
fi

cert_path="/etc/letsencrypt/live/$SSL_DOMAIN"
RED5_HOME="/usr/local/red5pro"
CURRENT_DIRECTORY="/home/ubuntu/red5pro-installer"

rpro_ssl_installer()
{
    log_i "Update SSL certificate and reload Red5Pro service ..."
    
    #rm $cert_path/tomcat.cer $cert_path/truststore.jks $cert_path/privkey-rsa.pem $cert_path/keystore.jks $cert_path/fullchain_and_key.p12
    
    local error=false
    rpro_ssl_fullchain="$cert_path/fullchain.pem"
    rpro_ssl_privkey="$cert_path/privkey.pem"
    rpro_ssl_fullchain_and_key="$cert_path/fullchain_and_key.p12"
    rpro_ssl_keystore_jks="$cert_path/keystore.jks"
    rpro_ssl_fullchain_and_key="$cert_path/fullchain_and_key.p12"
    rpro_ssl_tomcat_cer="$cert_path/tomcat.cer"
    rpro_ssl_trust_store="$cert_path/truststore.jks"
    
    openssl pkcs12 -export -in "$rpro_ssl_fullchain" -inkey "$rpro_ssl_privkey" -out "$rpro_ssl_fullchain_and_key" -password pass:"$SSL_PASSWORD" -name tomcat
    
    keytool_response=$(keytool -noprompt -importkeystore -deststorepass "$SSL_PASSWORD" -destkeypass "$SSL_PASSWORD" -destkeystore "$rpro_ssl_keystore_jks" -srckeystore "$rpro_ssl_fullchain_and_key" -srcstoretype PKCS12 -srcstorepass "$SSL_PASSWORD" -alias tomcat)
    # Check for keytool error
    if [[ ${keytool_response} == *"keytool error"* ]];then
        printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
        log_w "An error occurred while processing certificate.Please resolve the error(s) and try the SSL installer again."
        log_w "Error Details:"
        log_w "$keytool_response"
        error=true
    fi
    
    keytool_response=$(keytool -noprompt -export -alias tomcat -file "$rpro_ssl_tomcat_cer" -keystore "$rpro_ssl_keystore_jks" -storepass "$SSL_PASSWORD")
    # Check for keytool error
    if [[ ${keytool_response} == *"keytool error"* ]];then
        printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
        log_w "An error occurred while processing certificate.Please resolve the error(s) and try the SSL installer again."
        log_w "Error Details:"
        log_w "$keytool_response"
        error=true
    fi
    
    keytool_response=$(keytool -noprompt -import -trustcacerts -alias tomcat -file "$rpro_ssl_tomcat_cer" -keystore "$rpro_ssl_trust_store" -storepass "$SSL_PASSWORD")
    # Check for keytool error
    if [[ ${keytool_response} == *"keytool error"* ]];then
        printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
        log_w "An error occurred while processing certificate.Please resolve the error(s) and try the SSL installer again."
        log_w "Error Details:"
        log_w "$keytool_response"
        error=true
    fi
    
    if [ "$error" = false ];
    then
        log_i "Restart Red5Pro service..."
        systemctl restart red5pro
    else
        log_e "Failed to create keystore and etc. !!!"
        log_i "Please check path to certs in the config file ./red5pro/conf/red5.properties"
        log_i "Must be:
        rtmps.keystorepass=${SSL_PASSWORD}
        rtmps.keystorefile=/etc/letsencrypt/live/${SSL_DOMAIN}/keystore.jks
        rtmps.truststorepass=${SSL_PASSWORD}
        rtmps.truststorefile=/etc/letsencrypt/live/${SSL_DOMAIN}/truststore.jks"
        log_i "End check for exist path: /etc/letsencrypt/live/${SSL_DOMAIN}/"
        log_i "If something wrong, please do this steps:
        1. Delete folder /etc/letsencript
        2. Check red5.properties
        3. Start this scrypt with sudo or like root."
        exit
    fi
}

certbot_install(){
    sudo snap install core; sudo snap refresh core
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
    #sudo certbot certonly --standalone
}

rpro_ssl_get(){
    log_i "Getting a new certificate for domain: $SSL_DOMAIN ..."
    rpro_ssl_response=$(certbot certonly --non-interactive --standalone --email "$SSL_MAIL" --agree-tos -d "$SSL_DOMAIN" 2>&1 | tee /dev/tty)
    
    echo "$rpro_ssl_response" | grep 'Success' &> /dev/null
    if [ $? == 0 ]; then
        log_i "SSL Certificate successfully generated!"
    else
        log_e "SSL Certificate generation did not succeed. Please rectify any errors mentioned in the logging and try again! EXIT."
        log_e "Error Details: $rpro_ssl_response"
        error=1
    fi
}

rpro_ssl_config(){
    log_i "Red5pro SSL configuration ..."

    log_i "Configuring $RED5_HOME/conf/jee-container.xml"

    local http1='<!-- Non-secured transports for HTTP and WS -->'
    local http1_new='<!-- Non-secured transports for HTTP and WS --> <!--'

    local http2='<!-- Secure transports for HTTPS and WSS -->'
    local http2_new='--> <!-- Secure transports for HTTPS and WSS -->'

    sed -i -e "s|$http1|$http1_new|" -e "s|$http2|$http2_new|" "$RED5_HOME/conf/jee-container.xml"
    
    # Delete 1 line after <!-- Secure transports for HTTPS and WSS -->
    sed -i '/Secure transports for HTTPS and WSS/{n;d}' "$RED5_HOME/conf/jee-container.xml"

    # Delete first line before </beans>
    sed -i '$!N;/\n.*beans>/!P;D' "$RED5_HOME/conf/jee-container.xml"
    # Delete second line before </beans>
    sed -i '$!N;/\n.*beans>/!P;D' "$RED5_HOME/conf/jee-container.xml"


    log_i "Configuring: $RED5_HOME/conf/red5.properties"
    local https_port_pattern="https.port=.*"
    local https_port_replacement_value="https.port=443"
    
    local rtmps_keystorepass_pattern="rtmps.keystorepass=.*"
    local rtmps_keystorepass_replacement_value="rtmps.keystorepass=${SSL_PASSWORD}"
    local rtmps_keystorefile_pattern="rtmps.keystorefile=.*"
    local rtmps_keystorefile_replacement_value="rtmps.keystorefile=${cert_path}/keystore.jks"
    local rtmps_truststorepass_pattern="rtmps.truststorepass=.*"
    local rtmps_truststorepass_replacement_value="rtmps.truststorepass=${SSL_PASSWORD}"
    local rtmps_truststorefile_pattern="rtmps.truststorefile=.*"
    local rtmps_truststorefile_replacement_value="rtmps.truststorefile=${cert_path}/truststore.jks"
    
    sudo sed -i -e "s|$https_port_pattern|$https_port_replacement_value|" -e "s|$rtmps_keystorepass_pattern|$rtmps_keystorepass_replacement_value|" -e "s|$rtmps_keystorefile_pattern|$rtmps_keystorefile_replacement_value|" -e "s|$rtmps_truststorepass_pattern|$rtmps_truststorepass_replacement_value|" -e "s|$rtmps_truststorefile_pattern|$rtmps_truststorefile_replacement_value|"   "$RED5_HOME/conf/red5.properties"
}

if [[ "$SSL_ENABLE" == "true" ]] ; then
    log_i "SSL installation is enabled."
else
    exit 0
fi

error=0

while true ; do
    
    if [[ "$(dig +short $SSL_DOMAIN)" ]]; then
        log_i "DNS record for domain: $SSL_DOMAIN was found."
        log_i "Start SSL installation..."
        #systemctl stop red5pro
        certbot_install
        rpro_ssl_get
        if [[ $error == "0" ]]; then
            rpro_ssl_config
            rpro_ssl_installer
            break
        else
            log_w "Something worong with Certbot, getting certificate will repeat after 5 minutes..."
            sleep 120
            error=0
        fi
    else
        log_i "DNS record for domain: $SSL_DOMAIN was not found."
    fi
    sleep 60
done