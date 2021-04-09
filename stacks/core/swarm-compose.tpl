version: "3.2"

networks:
  traefik-net:
    driver: overlay
  mongo:
    driver: overlay
    attachable: true
  celery:
    driver: overlay
    attachable: true

volumes:
  mongo-data: {}
  mongo-cfg: {}

services:
  traefik:
    image: traefik:v2.4
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    networks:
      - traefik-net
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "/home/ubuntu/wholetale/traefik:/etc/traefik"
      - "/home/ubuntu/wholetale/traefik/acme:/acme"
    environment:
      - GODADDY_API_KEY=${godaddy_api_key}
      - GODADDY_API_SECRET=${godaddy_api_secret}
    deploy:
      replicas: 1
      labels:
        - "traefik.enable=false"
      placement:
        constraints:
          - "node.role == manager"

  mongo1:
    image: mongo:3.2
    networks:
      - mongo
    volumes:
      - mongo-data:/data/db
      - mongo-cfg:/data/configdb
    command: ["mongod", "--replSet", "rs1"]
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.labels.mongo.replica == 1
  mongo2:
    image: mongo:3.2
    networks:
      - mongo
    volumes:
      - mongo-data:/data/db
      - mongo-cfg:/data/configdb
    command: ["mongod", "--replSet", "rs1"]
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.labels.mongo.replica == 2
  mongo3:
    image: mongo:3.2
    networks:
      - mongo
    volumes:
      - mongo-data:/data/db
      - mongo-cfg:/data/configdb
    command: ["mongod", "--replSet", "rs1"]
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.labels.mongo.replica == 3
  girder:
    image: wholetale/girder:${version}
    networks:
      - celery
      - traefik-net
      - mongo
    environment:
      - DASHBOARD_URL=https://dashboard.${domain}
      - GOSU_USER=girder:girder
      - "GOSU_CHOWN=/tmp/data /tmp/ps"
    volumes:
      - "/mnt/homes:/tmp/data"
      - "/mnt/dms:/tmp/ps"
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "10"
        compress: "true"
    deploy:
      replicas: 1
      labels:
        - "traefik.frontend.rule=Host:girder.${domain},data.${domain}"
        - "traefik.enable=true"
        - "traefik.http.routers.girder.rule=Host(`girder.${domain}`) || Host(`data.${domain}`)"
        - "traefik.http.routers.girder.entrypoints=websecure"
        - "traefik.http.routers.girder.tls=true"
        - "traefik.http.routers.girder.tls.certresolver=default"
        - "traefik.http.routers.girder.tls.domains[0].main=*.${domain}"
        - "traefik.http.services.girder.loadbalancer.server.port=8080"
        - "traefik.http.services.girder.loadbalancer.passhostheader=true"
        - "traefik.docker.network=wt_traefik-net"
        - "traefik.http.middlewares.girder.forwardauth.address=http://girder:8080/api/v1/instance/authorize/"
        - "traefik.http.middlewares.girder.forwardauth.trustforwardheader=true"
      placement:
        constraints:
          - node.labels.storage == 1
  redis:
    image: redis
    networks:
      - celery
    deploy:
      replicas: 1
      labels:
        - "traefik.enable=false"

  dashboard:
    image: wholetale/ngx-dashboard:${version}
    networks:
      - traefik-net
    environment:
      - GIRDER_API_URL=https://girder.${domain}/api/v1
      - DASHBOARD_URL=https://dashboard.${domain}
      - DATAONE_URL=${dataone_url}
      - AUTH_PROVIDER=Globus
    deploy:
      replicas: 1
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.dashboard.rule=Host(`dashboard.${domain}`)"
        - "traefik.http.routers.dashboard.entrypoints=websecure"
        - "traefik.http.routers.dashboard.tls=true"
        - "traefik.http.routers.dashboard.tls.certresolver=default"
        - "traefik.http.routers.dashboard.tls.domains[0].main=*.${domain}"
        - "traefik.http.services.dashboard.loadbalancer.server.port=80"
        - "traefik.http.services.dashboard.loadbalancer.passhostheader=true"
        - "traefik.docker.network=wt_traefik-net"

  registry:
    image: registry:2.6
    networks:
      - traefik-net
    volumes:
      - "/mnt/registry:/var/lib/registry"
      - "/mnt/registry/auth:/auth:ro"
    environment:
      - REGISTRY_AUTH=htpasswd
      - REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm"
      - REGISTRY_AUTH_HTPASSWD_PATH=/auth/registry.password
    deploy:
      replicas: 1
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.registry.rule=Host(`registry.${domain}`)"
        - "traefik.http.routers.registry.entrypoints=websecure"
        - "traefik.http.routers.registry.tls=true"
        - "traefik.http.routers.registry.tls.certresolver=default"
        - "traefik.http.routers.registry.tls.domains[0].main=*.${domain}"
        - "traefik.http.services.registry.loadbalancer.server.port=5000"
        - "traefik.http.services.registry.loadbalancer.passhostheader=true"
        - "traefik.docker.network=wt_traefik-net"
      placement:
        constraints:
          - node.labels.storage == 1
