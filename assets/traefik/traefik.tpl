graceTimeOut = "10s"
debug = false
checkNewVersion = false
logLevel = "INFO"

# If set to true invalid SSL certificates are accepted for backends.
# Note: This disables detection of man-in-the-middle attacks so should only be used on secure backend networks.
# Optional
# Default: false
#
# InsecureSkipVerify = true

defaultEntryPoints = ["http", "https"]

[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
    entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]
    #MinVersion = "VersionTLS12"
    #CipherSuites = ["TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"]
    MinVersion = "VersionTLS10"
    CipherSuites = ["TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305", "TLS_RSA_WITH_AES_128_CBC_SHA", "TLS_RSA_WITH_AES_256_CBC_SHA"]

[acme]
email = "bgates@microsoft.com"   # FIXME
storage = "/acme/acme.json"
entryPoint = "https"
acmeLogging = true

[acme.httpChallenge]
entryPoint = "http"

[acme.dnsChallenge]
provider = "godaddy"
delayBeforeCheck = 0

[[acme.domains]]
main = "*.${subdomain}.${domain}"

[[acme.domains]]
main = "dashboard-${subdomain}.${domain}"

[web]
address = ":8080"

[docker]
endpoint = "unix:///var/run/docker.sock"
domain = "${subdomain}.${domain}"
watch = true
exposedbydefault = true
swarmmode = true
