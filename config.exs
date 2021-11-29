# This file can be used for additional static configuration
import Config

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
    "*.pawoo.net",
    "*.baraag.net"
  ],
  federated_timeline_removal: [
    "gameliberty.club",
    "youjo.love",
    "hentai.baby"
  ],
  reject: [
    "eunomia.social",
    "*.eunomia.social",
    "childpawn.shop",
    "freak.university",
    "wintermute.fr.to",
    "hentai.baby",
    "youjo.love"
  ]

# Media proxy
config :pleroma, :media_proxy,
  enabled: true,
  base_url: "https://social.silkky.cloud"
const :pleroma, :media_preview_proxy,
  enabled: true
