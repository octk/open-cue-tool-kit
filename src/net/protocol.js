const protons = require("protons");

const { Request } = protons(`
message Request {
  enum Type {
    NEW_PRODUCTION = 0;
  }

  required Type type = 1;
  optional NewProduction newProduction = 2;
}

message NewProduction {
  required string title = 1;
  required string id = 2;
}
`);

export default Request;
