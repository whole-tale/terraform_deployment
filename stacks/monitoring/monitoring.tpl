version: "3.2"

networks:
  outside:
    external:
      name: "host"

services:
  checkmk-agent:
    image: wholetale/check_mk:${version}
    networks:
      - outside
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    deploy:
      mode: global
    environment:
      - NAMESPACE=wt
      - GIRDER_URL=https://girder.${subdomain}.${domain}
      - GIRDER_API_KEY=${monitoring_api_key}
      - TALE_ID=${monitoring_tale_id}
