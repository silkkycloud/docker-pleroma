# This file can be used for additional static configuration
import Config

config :pleroma, configurable_from_database: true

# Welcome message
config :pleroma, :welcome,
  email: [
    enabled: true,
    sender: {"Pleroma Silkky.Cloud", "noreply@robot.silkky.cloud"},
    subject: "Welcome to <%= instance_name %>!"
  ]

# MRF policies
config :pleroma, :mrf_simple,
  media_nsfw: [
    {"*.pawoo.net"},
    {"*.baraag.net"}
  ],
  federated_timeline_removal: [
    {"gameliberty.club"},
    {"youjo.love", "Illegal content"},
    {"hentai.baby", "Illegal content"}
  ],
  reject: [
    {"eunomia.social", "Privacy Concerns"},
    {"*.eunomia.social", "Privacy Concerns"},
    {"childpawn.shop", "Illegal content"},
    {"freak.university", "Illegal content"},
    {"wintermute.fr.to", "Illegal content"},
    {"hentai.baby", "Illegal content"},
    {"youjo.love", "Illegal content"}
  ]

# Media proxy
config :pleroma, :media_proxy,
  enabled: true
config :pleroma, :media_preview_proxy,
  enabled: true
