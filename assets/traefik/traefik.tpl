[entryPoints]
  [entryPoints.web]
    address = ":80"
    [entryPoints.web.http]
      [entryPoints.web.http.redirections]
        [entryPoints.web.http.redirections.entryPoint]
          to = "websecure"
          scheme = "https"

  [entryPoints.websecure]
    address = ":443"

[providers]
  providersThrottleDuration = "2s"
  [providers.docker]
    watch = true
    endpoint = "unix:///var/run/docker.sock"
    exposedByDefault = true
    swarmMode = true
    swarmModeRefreshSeconds = "15s"
    httpClientTimeout = "0s"
    defaultRule = "Host(`{{ trimPrefix `/` .Name }}.${domain}`)"


[tls.options]
  [tls.options.default]
    minVersion = "VersionTLS10"
    cipherSuites = [
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
      "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
      "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305",
      "TLS_RSA_WITH_AES_128_CBC_SHA",
      "TLS_RSA_WITH_AES_256_CBC_SHA"
   ]

[api]
  debug = false
  dashboard = true
  insecure = true

[log]
  level = "DEBUG"

[accessLog]
  format = "json"
  bufferingSize = 0
  [accessLog.filters]
    statusCodes = ["200", "300-302"]
    retryAttempts = true
    minDuration = "0s"
  [accessLog.fields]
    defaultMode = "keep"
    [accessLog.fields.names]
      ClientUsername = "drop"
    [accessLog.fields.headers]
      defaultMode = "keep"
      [accessLog.fields.headers.names]
        Authorization = "drop"
        Content-Type = "keep"
        User-Agent = "redact"

[certificatesResolvers]
  [certificatesResolvers.default]
    [certificatesResolvers.default.acme]
      email = "bgates@microsoft.com"
      storage = "/acme/acme.json"
      [certificatesResolvers.default.acme.dnsChallenge]
        provider = "godaddy"
        delayBeforeCheck = "30m0s"
        #entryPoint = "https"
