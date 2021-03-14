const protons = require("protons");

const { Request } = protons(`
message Request {
  enum Type {
    SHARE_PRODUCTION = 0;
    ACCEPT_INVITE = 1;
    BEGIN_SHOW = 2;
    CUE_NEXT_ACTOR = 3;
  }

  required Type type = 1;
  optional ShareProduction shareProduction = 2;
  optional AcceptInvite acceptInvite = 3;
  optional BeginShow beginShow = 4;
}

message ShareProduction {
  required string title = 1;
  required string id = 2;
}

message AcceptInvite {
  required string identity = 1;
  required string name = 2;
}

message BeginShow {
  map<string, string> actorsByPart = 1;
}

`);

export default Request;
