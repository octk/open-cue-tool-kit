import Websockets from "libp2p-websockets"; // Transports
import WebrtcStar from "libp2p-webrtc-star";
import wrtc from "wrtc";
import Mplex from "libp2p-mplex"; // Stream Muxer
import { NOISE } from "libp2p-noise"; // Connection Encryption
import Secio from "libp2p-secio";
import Bootstrap from "libp2p-bootstrap"; // Peer Discovery
import KadDHT from "libp2p-kad-dht";
import Gossipsub from "libp2p-gossipsub"; // PubSub implementation

export default {
  addresses: {
    listen: [`/dns4/wrtc-star2.sjc.dwebops.pub/tcp/443/wss/p2p-webrtc-star`]
  },
  modules: {
    transport: [Websockets, WebrtcStar],
    streamMuxer: [Mplex],
    connEncryption: [NOISE, Secio],
    peerDiscovery: [Bootstrap],
    dht: KadDHT,
    pubsub: Gossipsub
  },
  config: {
    transport: {
      [WebrtcStar.prototype[Symbol.toStringTag]]: {
        wrtc
      }
    },
    peerDiscovery: {
      bootstrap: {
        list: [
          "/dnsaddr/sjc-1.bootstrap.libp2p.io/tcp/4001/ipfs/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN"
        ]
      }
    },
    dht: {
      enabled: true,
      randomWalk: {
        enabled: true
      }
    },
    pubsub: {
      enabled: true,
      emitSelf: true, // Recieve own messages
      scoreParams: {
        IPColocationFactorWeight: 0 // Do not penalize IP-sharing nodes
      }
    }
  }
};
