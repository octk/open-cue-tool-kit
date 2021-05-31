import { expect } from "chai";
import Vuex from "vuex";

var appInjector = require("inject-loader!@/store/app.js");
var app = appInjector({ lodash: {} });

var directorInjector = require("inject-loader!@/store/director.js");
var director = directorInjector({
  "../core/casting": {},
  "@ionic/vue": {}
});

var netInjector = require("inject-loader!@/store/net.js");
var net = netInjector({
  "../core/p2p": {},
  "../core/canon": {}
});

describe("store/index", () => {
  it("initializes store", () => {
    const store = new Vuex.Store({
      modules: {
        app,
        director,
        net
      }
    });

    expect(store && null).to.be.null;
  });
});
