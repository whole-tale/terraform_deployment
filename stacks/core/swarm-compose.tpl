version: "3.2"

networks:
  traefik-net:
    driver: overlay
    driver_opts:
      com.docker.network.driver.mtu: ${mtu}
  mongo:
    driver: overlay
    driver_opts:
      com.docker.network.driver.mtu: ${mtu}
    attachable: true
  celery:
    driver: overlay
    driver_opts:
      com.docker.network.driver.mtu: ${mtu}
    attachable: true

volumes:
  mongo-data: {}
  mongo-cfg: {}

services:
  traefik:
    image: traefik:alpine
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    networks:
      - traefik-net
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "/home/core/wholetale/traefik:/etc/traefik"
      - "/home/core/wholetale/traefik/acme:/acme"
    environment:
      - GODADDY_API_KEY=${godaddy_api_key}
      - GODADDY_API_SECRET=${godaddy_api_secret}
    deploy:
      replicas: 1
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
    volumes:
      - "/mnt/homes:/tmp/wt-home-dirs"
      - "/mnt/homes:/tmp/wt-tale-dirs"
    deploy:
      replicas: 1
      labels:
        - "traefik.frontend.rule=Host:girder.${subdomain}.${domain}"
        - "traefik.port=8080"
        - "traefik.enable=true"
        - "traefik.docker.network=wt_traefik-net"
        - "traefik.frontend.passHostHeader=true"
        - "traefik.frontend.entryPoints=https"
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
    image: wholetale/dashboard:${version}
    networks:
      - traefik-net
    environment:
      - GIRDER_API_URL=https://girder.${subdomain}.${domain}
    deploy:
      replicas: 1
      labels:
        - "traefik.port=80"
        - "traefik.frontend.rule=Host:dashboard.${subdomain}.${domain}"
        - "traefik.enable=true"
        - "traefik.docker.network=wt_traefik-net"
        - "traefik.frontend.passHostHeader=true"
        - "traefik.frontend.entryPoints=https"

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
        - "traefik.port=5000"
        - "traefik.frontend.rule=Host:registry.${domain}"
        - "traefik.docker.network=wt_traefik-net"
        - "traefik.frontend.passHostHeader=true"
        - "traefik.frontend.entryPoints=https"
      placement:
        constraints:
          - node.labels.storage == 1
