FROM alpine:latest

RUN apk update && apk add --no-cache iptables iproute2

COPY setup_firewall.sh /usr/local/bin/setup_firewall.sh

RUN chmod +x /usr/local/bin/setup_firewall.sh

CMD ["/bin/sh", "-c", "/usr/local/bin/setup_firewall.sh && tail -f /dev/null"]
