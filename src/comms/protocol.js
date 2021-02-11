const protons = require("protons");

const { Request } = protons(`
message Request {
  enum Type {
    SEND_MESSAGE = 0;
    UPDATE_PEER = 1;
    STATS = 2;
    NEW_NUMBER = 3;
  }

  required Type type = 1;
  optional SendMessage sendMessage = 2;
  optional UpdatePeer updatePeer = 3;
  optional Stats stats = 4;
  optional NewNumber newNumber = 5;
}

message NewNumber {
  required int64 seed = 1;
}

message SendMessage {
  required bytes data = 1;
  required int64 created = 2;
  required bytes id = 3;
}

message UpdatePeer {
  optional bytes userHandle = 1;
}

message Stats {
  enum NodeType {
    GO = 0;
    NODEJS = 1;
    BROWSER = 2;
  }

  repeated bytes connectedPeers = 1;
  optional NodeType nodeType = 2;
}
`);

export default Request;
