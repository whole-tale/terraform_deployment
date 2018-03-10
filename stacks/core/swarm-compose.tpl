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
    image: wholetale/girder:latest
    networks:
      - celery
      - traefik-net
      - mongo
    deploy:
      replicas: 1
      labels:
        - "traefik.frontend.rule=Host:girder.${domain}"
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
    labels:
      - "traefik.enable: false"
    deploy:
      replicas: 1

  dashboard:
    image: wholetale/dashboard:stable
    networks:
      - traefik-net
    environment:
      - GIRDER_API_URL=https://girder.${domain}
    deploy:
      replicas: 1
      labels:
        - "traefik.port=80"
        - "traefik.frontend.rule=Host:dashboard.${domain}"
        - "traefik.enable=true"
        - "traefik.docker.network=wt_traefik-net"
        - "traefik.frontend.passHostHeader=true"
        - "traefik.frontend.entryPoints=https"
