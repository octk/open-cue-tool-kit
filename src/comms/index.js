import Libp2p from "libp2p";
import libP2pConfig from "./libp2pConfig";
import protocol from "./protocol.js";

class CueScriptProtocol {
  constructor(libP2pNode, handlers) {
    this.lobbyTopic = this.pubsubFromId("lobby");
    this.libp2p = libP2pNode;
    this.handlers = handlers;

    this.connectedPeers = new Set();

    // Store connections, and keep stats updated
    this.libp2p.connectionManager.on("peer:connect", connection => {
      if (this.connectedPeers.has(connection.remotePeer.toB58String())) return;
      this.connectedPeers.add(connection.remotePeer.toB58String());
    });
    this.libp2p.connectionManager.on("peer:disconnect", connection => {
      if (this.connectedPeers.delete(connection.remotePeer.toB58String())) {
        console.error("disconnect", connection);
      }
    });

    // Update on protocol events
    if (!this.libp2p.isStarted())
      console.error("Oops. Tried to subscribe before lip2p was started.");
    this.libp2p.pubsub.subscribe(
      this.lobbyTopic,
      this.updateFromProtocolEvent(this)
    );
  }

  updateFromProtocolEvent(self) {
    // Closure around this as self to pass handlers
    return function(message) {
      const { onNewProduction } = self.handlers;
      try {
        const request = protocol.decode(message.data);
        switch (request.type) {
          case protocol.Type.NEW_PRODUCTION:
            console.log(request.newProduction);
            onNewProduction(request.newProduction);
            break;
          default:
          //No-op
        }
      } catch (err) {
        console.error(err);
      }
    };
  }

  async createNewProduction(title) {
    const id = (~~(Math.random() * 1e9)).toString(36) + Date.now();
    console.log(protocol);
    await this.libp2p.pubsub.publish(
      this.lobbyTopic,
      protocol.encode({
        type: protocol.Type.NEW_PRODUCTION,
        newProduction: {
          title,
          id
        }
      })
    ); // Open casting to everyone

    await this.libp2p.pubsub.subscribe(
      this.pubsubFromId(id),
      this.updateFromProduction
    ); // Listen for responses
    return id;
  }

  async joinProduction(id) {
    await this.libp2p.pubsub.subscribe(
      this.pubsubFromId(id),
      this.updateFromProduction
    );
  }

  // Utils
  pubsubFromId(id) {
    return `/libp2p/dev/cueCannon/1.0.0/${id}`;
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
    const { onNewProduction, acceptInvite, nextCue } = this;

    this.cueScriptProtocol = new CueScriptProtocol(this.libP2pNode, {
      onNewProduction,
      acceptInvite,
      nextCue
    });
  }

  // User intentions involving the network
  async makeInvite(title) {
    const id = await this.cueScriptProtocol.createNewProduction(title);
    return id;
  }
  async acceptInvite(id) {
    await this.cueScriptProtocol.joinProduction(id);
  }
  nextCue() {
    console.log("nextCue not implemented");
  }
}
