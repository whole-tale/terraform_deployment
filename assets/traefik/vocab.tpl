[http]
  [http.routers]
    [http.routers.vocabularies]
      rule="Host(`vocabularies.${domain}`)"
      service="vocabularies"
      entryPoints=["web", "websecure"]
      middlewares=["repo-prefix"]
      tls = true

  [http.middlewares]
    [http.middlewares.repo-prefix.addPrefix]
      prefix = "/serialization-format"

  [http.services]
    [http.services.vocabularies]
      [http.services.vocabularies.loadBalancer]
        passHostHeader = false
        [[http.services.vocabularies.loadBalancer.servers]]
          url="https://whole-tale.github.io/"
