#!/bin/bash

# SM_SSL (the domain to wait for comes from TRAEFIK_HOST in the SM .env)

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

HOME="/home/ubuntu/red5pro-installer"
SM_HOME="/usr/local/stream-manager"

# Readiness endpoint: Traefik routes PathPrefix(/as/v1/admin) on the plain
# "web" entrypoint and strips /as/v1/, so this reaches as-admin's own
# /admin/healthz.
SM_HEALTH_URL="http://localhost/as/v1/admin/healthz"
SM_READY_TIMEOUT=1800
SM_READY_INTERVAL=10
SM_READY_STABLE_CHECKS=3

authority_ns=""

# Query the zone's authoritative name server rather than the recursive
# resolver. This script starts polling before the operator has created the
# A record, so the first lookup caches an NXDOMAIN for the SOA negative TTL
# (often 30 minutes) in both systemd-resolved and the upstream resolver, and
# the record would stay invisible long after it exists. Falls back to the
# recursive resolver if the authoritative server cannot be determined or
# does not answer.
discover_authority_ns() {
    local zone="$1"
    while [[ "$zone" == *.* ]]; do
        authority_ns=$(dig +short SOA "$zone" | awk 'NR==1 {print $1}')
        if [ -n "$authority_ns" ]; then
            log_i "Authoritative name server for zone $zone: $authority_ns"
            return
        fi
        zone="${zone#*.}"
    done
}

# Restarting sm.service while docker compose is still bringing the stack up
# corrupts the startup, so wait for the stack to actually serve traffic
# instead of guessing with a fixed sleep. Requires several consecutive
# successes so a single early 200 during startup does not release the gate.
wait_for_sm_ready() {
    local elapsed=0
    local streak=0
    local code

    log_i "Waiting for sm.service to become active..."
    while ! systemctl is-active --quiet sm.service; do
        if [ "$elapsed" -ge "$SM_READY_TIMEOUT" ]; then
            log_w "sm.service is still not active after ${elapsed}s, applying SSL configuration anyway"
            return 1
        fi
        sleep "$SM_READY_INTERVAL"
        elapsed=$((elapsed + SM_READY_INTERVAL))
    done
    log_i "sm.service is active after ${elapsed}s, waiting for $SM_HEALTH_URL to answer HTTP 200"

    while true; do
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$SM_HEALTH_URL")
        if [ "$code" = "200" ]; then
            streak=$((streak + 1))
            if [ "$streak" -ge "$SM_READY_STABLE_CHECKS" ]; then
                log_i "Stream Manager is serving traffic after ${elapsed}s"
                return 0
            fi
        else
            if [ "$streak" -gt 0 ]; then
                log_w "Stream Manager health check flapped (HTTP $code), restarting the stability counter"
            fi
            streak=0
        fi

        if [ "$elapsed" -ge "$SM_READY_TIMEOUT" ]; then
            log_w "Stream Manager did not become healthy after ${elapsed}s (last HTTP code: $code), applying SSL configuration anyway"
            return 1
        fi
        sleep "$SM_READY_INTERVAL"
        elapsed=$((elapsed + SM_READY_INTERVAL))
    done
}

# Best effort: the restart is already done at this point, so this only makes
# the outcome visible in the log instead of leaving a bare "restarted" line.
# Probes over HTTPS with -k because the ACME certificate may still be pending
# and Traefik serves its default certificate until it arrives.
verify_ssl_restart() {
    local domain="$1"
    local elapsed=0
    local code

    while [ "$elapsed" -lt "$SM_READY_TIMEOUT" ]; do
        if systemctl is-active --quiet sm.service; then
            code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 5 --resolve "$domain:443:127.0.0.1" "https://$domain/as/v1/admin/healthz")
            if [ "$code" = "200" ]; then
                log_i "Stream Manager restarted and serving HTTPS after ${elapsed}s"
                return 0
            fi
        fi
        sleep "$SM_READY_INTERVAL"
        elapsed=$((elapsed + SM_READY_INTERVAL))
    done

    log_w "Stream Manager did not answer HTTPS on $domain after ${elapsed}s (last HTTP code: ${code:-none}) - check 'systemctl status sm.service' and 'docker compose logs' in $SM_HOME"
    return 1
}

# Must stay free of logging: the caller captures stdout, so any log line
# here would be read back as a resolved address.
resolve_domain() {
    local domain="$1"
    local result=""

    if [ -n "$authority_ns" ]; then
        result=$(dig +short +time=3 +tries=1 "$domain" @"$authority_ns")
    fi
    if [ -z "$result" ]; then
        result=$(dig +short "$domain")
    fi
    echo "$result"
}

if [ "$SM_SSL" == "letsencrypt" ]; then

    # TRAEFIK_HOST is the concrete FQDN Traefik serves and that the ACME
    # tls-challenge validates, so it is the only name worth waiting for.
    ssl_domain=$(grep -E '^TRAEFIK_HOST=' "$SM_HOME/.env" | tail -n 1 | cut -d= -f2-)
    if [ -z "$ssl_domain" ]; then
        log_e "TRAEFIK_HOST is not set in $SM_HOME/.env - cannot tell which domain to wait for"
        exit 1
    fi
    log_i "Waiting for DNS record of domain: $ssl_domain"

    discover_authority_ns "$ssl_domain"
    if [ -z "$authority_ns" ]; then
        log_w "Could not determine an authoritative name server for $ssl_domain, falling back to the recursive resolver - a cached NXDOMAIN may delay detection by up to the zone's negative TTL"
    fi

    while true; do
        if [ -z "$authority_ns" ]; then
            discover_authority_ns "$ssl_domain"
        fi
        if [[ "$(resolve_domain "$ssl_domain")" ]]; then
            log_i "DNS record for domain: $ssl_domain was found."
            if [ -f "$HOME/docker-compose.ssl.yml" ]; then
                wait_for_sm_ready
                log_i "Applying SSL configuration."
                cp "$HOME/docker-compose.ssl.yml" "$SM_HOME/"

                current_compose_files=$(grep -E '^COMPOSE_FILE=' "$SM_HOME/.env" | tail -n 1 | cut -d= -f2-)
                if [ -z "$current_compose_files" ]; then
                    current_compose_files="docker-compose.yml"
                fi

                if [[ ":$current_compose_files:" == *":docker-compose.ssl.yml:"* ]]; then
                    compose_files="$current_compose_files"
                else
                    overlays="${current_compose_files#docker-compose.yml}"
                    overlays="${overlays#:}"
                    compose_files="docker-compose.yml:docker-compose.ssl.yml"
                    if [ -n "$overlays" ]; then
                        compose_files="$compose_files:$overlays"
                    fi
                fi

                log_i "Updating COMPOSE_FILE for SSL: $compose_files"
                sed -i "s|^COMPOSE_FILE=.*|COMPOSE_FILE=$compose_files|" "$SM_HOME/.env"
                log_i "Restarting Stream Manager service to apply SSL configuration"
                systemctl restart sm.service
                verify_ssl_restart "$ssl_domain"
                break
            else
                log_e "File $HOME/docker-compose.ssl.yml not found"
                ls -la "$HOME/"
                exit 1
            fi
        else
            log_i "DNS record for domain: $ssl_domain was not found."
        fi
        sleep 60
    done
fi