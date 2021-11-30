# This file can be used for additional static configuration
import Config

config :pleroma, configurable_from_database: true

# Media proxy
config :pleroma, :media_proxy,
  enabled: true
config :pleroma, :media_preview_proxy,
  enabled: true
