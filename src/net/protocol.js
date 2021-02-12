const protons = require("protons");

const { Request } = protons(`
message Request {
  enum Type {
    NEW_PRODUCTION = 0;
    ACCEPT_INVITE = 1;
  }

  required Type type = 1;
  optional NewProduction newProduction = 2;
  optional AcceptInvite acceptInvite = 3;
}

message NewProduction {
  required string title = 1;
  required string id = 2;
}

message AcceptInvite {
  required string identity = 1;
}
`);

export default Request;
