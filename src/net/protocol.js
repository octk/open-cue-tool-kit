const protons = require("protons");

const { Request } = protons(`
message Request {
  enum Type {
    NEW_PRODUCTION = 0;
    ACCEPT_INVITE = 1;
    BEGIN_SHOW = 2;
  }

  required Type type = 1;
  optional NewProduction newProduction = 2;
  optional AcceptInvite acceptInvite = 3;
  optional BeginShow beginShow = 4;
}

message NewProduction {
  required string title = 1;
  required string id = 2;
}

message AcceptInvite {
  required string identity = 1;
}

message BeginShow {
  required repeated PartActorPair actorsByPart = 1;
}

message PartActorPair {
  string part = 1;
  string actor = 2;
}
`);

export default Request;
