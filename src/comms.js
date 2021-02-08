// Libp2p Core
const Libp2p = require("libp2p");
// Transports
const Websockets = require("libp2p-websockets");
const WebrtcStar = require("libp2p-webrtc-star");
const wrtc = require("wrtc");
// Stream Muxer
const Mplex = require("libp2p-mplex");
// Connection Encryption
const { NOISE } = require("libp2p-noise");
const Secio = require("libp2p-secio");
// Chat over Pubsub
const PubsubChat = require("./chat");
// Peer Discovery
const Bootstrap = require("libp2p-bootstrap");
const KadDHT = require("libp2p-kad-dht");
// PubSub implementation
const Gossipsub = require("libp2p-gossipsub");

const libP2pConfig = {
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
    }
  }
};

export default class Comms {
  async init() {
    // Initialize and set debugging
    this.libP2pNode = await Libp2p.create(libP2pConfig);
    this.libP2pNode.connectionManager.on("peer:connect", connection => {
      console.log(`Connected to ${connection.remotePeer.toB58String()}`);
    });
    await this.libP2pNode.start();

    // Begin protocol
    this.cueScriptProtocol = new CueScriptProtocol(this.libhP2pNode, 
      {acceptInvite: this.acceptInvite,
        nextCue: this.nextCue
      });
  }

  // User intentions involving the network
  makeInvite() {
    console.log("makeInvite")
    const {productionId} = await this.cueScriptProtocol.createNewProduction();
    return productionId
  }
  acceptInvite(productionId) {
    console.log("productionId") 
  }
  nextCue() {
    console.log("nextCue");
  }
}
