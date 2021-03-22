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
        // console.error("disconnect", connection);
      }
    });

    // Update on protocol events
    if (!this.libp2p.isStarted())
      console.error("Oops. Tried to subscribe before lip2p was started.");
    this.libp2p.pubsub.subscribe(
      this.lobbyTopic,
      this.updateFromProtocolEvent(this)
    );

    this.libp2p.connectionManager.on("peer:connect", handlers.onNewActor);
  }

  // Responses to messages
  updateFromProtocolEvent(self) {
    // Closure around this as self to pass handlers
    return function(message) {
      const {
        onShareProduction,
        onAcceptInvite,
        onBeginShow,
        onCueNextActor
      } = self.handlers;
      try {
        const request = protocol.decode(message.data);
        switch (request.type) {
          case protocol.Type.SHARE_PRODUCTION:
            onShareProduction(request.shareProduction);
            break;
          case protocol.Type.ACCEPT_INVITE:
            onAcceptInvite(request.acceptInvite);
            break;
          case protocol.Type.BEGIN_SHOW:
            onBeginShow(request.beginShow);
            break;
          case protocol.Type.CUE_NEXT_ACTOR:
            onCueNextActor();
            break;
          default:
          //No-op
        }
      } catch (err) {
        console.error(err);
      }
    };
  }

  // General Messages
  // (empty)

  // Director Messages
  async createNewProduction(title) {
    const id = (~~(Math.random() * 1e9)).toString(36) + Date.now();
    const production = await this.shareProduction({ title, id });
    return production;
  }

  async shareProduction({ title, id }) {
    // FIXME all productions are on the same channel

    await this.libp2p.pubsub.publish(
      this.lobbyTopic,
      protocol.encode({
        type: protocol.Type.SHARE_PRODUCTION,
        shareProduction: {
          title,
          id
        }
      })
    );

    return { title, id };
  }

  async beginShow(actorsByPart) {
    await this.libp2p.pubsub.publish(
      this.pubsubFromId(),
      protocol.encode({
        type: protocol.Type.BEGIN_SHOW,
        beginShow: { actorsByPart }
      })
    ); // Empty b/c ids broken, fixme is below
  }

  // Actor messages
  async joinProduction(id, userHandle, name) {
    await this.libp2p.pubsub.publish(
      this.pubsubFromId(id),
      protocol.encode({
        type: protocol.Type.ACCEPT_INVITE,
        acceptInvite: {
          identity: userHandle,
          name
        }
      })
    );
  }

  async cueNextActor() {
    await this.libp2p.pubsub.publish(
      this.pubsubFromId(),
      protocol.encode({
        type: protocol.Type.CUE_NEXT_ACTOR
      })
    ); // Empty b/c ids broken, fixme is below
  }

  // Utils
  pubsubFromId(/*id*/) {
    // For now, publish all to one channel FIXME
    return `/libp2p/dev/cueCannon/1.0.0/lobby`;
  }
}

export default class P2p {
  async init() {
    // Initialize and set debugging
    this.libP2pNode = await Libp2p.create(libP2pConfig);
    this.userHandle = this.libP2pNode.peerId.toB58String();
    await this.libP2pNode.start();

    // Define handlers and begin protocol
    const {
      onShareProduction,
      onAcceptInvite,
      onNewActor,
      onBeginShow,
      onCueNextActor
    } = this;

    this.cueScriptProtocol = new CueScriptProtocol(this.libP2pNode, {
      onShareProduction,
      onAcceptInvite,
      onNewActor,
      onBeginShow,
      onCueNextActor
    });
  }

  // Director messages
  async makeInvite(title) {
    const production = await this.cueScriptProtocol.createNewProduction(title);
    return production;
  }
  async shareProduction(production) {
    return await this.cueScriptProtocol.shareProduction(production);
  }
  async acceptInvite({ id, name }) {
    await this.cueScriptProtocol.joinProduction(id, this.userHandle, name);
    return this.userHandle;
  }
  async beginShow({ actorsByPart }) {
    await this.cueScriptProtocol.beginShow(actorsByPart);
  }

  // Actor messages
  async cueNextActor() {
    await this.cueScriptProtocol.cueNextActor();
  }
}
