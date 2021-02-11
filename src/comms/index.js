import Libp2p from "libp2p"; 
import Websockets from "libp2p-websockets"; // Transports
import WebrtcStar from "libp2p-webrtc-star";
import wrtc from "wrtc";
import Mplex from "libp2p-mplex"; // Stream Muxer
import { NOISE } from "libp2p-noise"; // Connection Encryption
import Secio from "libp2p-secio";
import Bootstrap from "libp2p-bootstrap"; // Peer Discovery
import KadDHT from "libp2p-kad-dht";
import Gossipsub from "libp2p-gossipsub"; // PubSub implementation

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

class CueScriptProtocol {
  constructor(libP2pNode, handlers) {
    this.libp2p = libP2pNode;
    this.handlers = handlers;

    this.useHandles = new Map([[this.libp2p.peerId.toB58String(), "Me"]]);
    this.connectedPeers = new Set();

    // Store connections, and keep stats updated
    this.libp2p.connectionManager.on("peer:connect", (connection) => {
      if (this.connectedPeers.has(connection.remotePeer.toB58String())) return;
      this.connectedPeers.add(connection.remotePeer.toB58String());
      this.sendStats(Array.from(this.connectedPeers));
    });
    this.libp2p.connectionManager.on("peer:disconnect", (connection) => {
      if (this.connectedPeers.delete(connection.remotePeer.toB58String())) {
        this.sendStats(Array.from(this.connectedPeers));
      }
    });

    // Update on protocol events
    if (!this.libp2p.isStarted()) console.error("Oops. Tried to subscribe before lip2p was started.")
    this.libp2p.pubsub.subscribe("/libp2p/dev/cueCannon/1.0.0", this.updateFromProtocolEvent) 
  }

  updateFromProtocolEvent(message) {
    try {
      const request = Request.decode(message.data);
      switch(request.type) {
        case Request.Type.UPDATE_PEER:
          //eslint-disable-next-line
          const newHandle = request.updatePeer.userHandle.toString();
          console.info(`System: ${message.from} is now ${newHandle}`)
          this.userHandles.set(message.from, newHandle);
          break;
        default:
          //No-op
      }
    } catch(err) {
      console.error(err)
    }
  }

  async sendStats(connectedPeers) {
    const msg = Request.encode({
      type: Request.Type.STATS,
      stats: {
        connectedPeers,
        nodeType: Stats.NodeType.NODEJS,
      },
    });

    try {
      await this.libp2p.pubsub.publish(this.topic, msg);
    } catch (err) {
      console.error("Could not publish stats update", err);
    }
  }

  createNewProduction() {
    const id = (~~ (Math.random() * 1e9)).toString(36) + Date.now()
    return id;
  }
}

export default class Comms {
  async init() {
    // Initialize and set debugging
    this.libP2pNode = await Libp2p.create(libP2pConfig);
    this.libP2pNode.connectionManager.on("peer:connect", connection => {
      console.log(`Connected to ${connection.remotePeer.toB58String()}`);
    });
    await this.libP2pNode.start();

    // Define handlers and begin protocol
    const { acceptInvite, nextCue } = this;

    this.cueScriptProtocol = new CueScriptProtocol(this.libP2pNode, { acceptInvite, nextCue })
  }

  // User intentions involving the network
  makeInvite() {
    console.log("makeInvite not implemented")
    const { productionId } = await this.cueScriptProtocol.createNewProduction();
    return productionId
  }
  acceptInvite(productionId) {
    console.log("productionId not implemented") 
  }
  nextCue() {
    console.log("nextCue not implemented");
  }
}
