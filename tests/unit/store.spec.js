import { expect } from "chai";
import Vuex from "vuex";
import Canon from "./mock/canon.js";
import p2p from "./mock/p2p";

//  ___        _           _                          _
// |_ _|_ __  (_) ___  ___| |_   _ __ ___   ___   ___| | __
//  | || '_ \ | |/ _ \/ __| __| | '_ ` _ \ / _ \ / __| |/ /
//  | || | | || |  __/ (__| |_  | | | | | | (_) | (__|   <
// |___|_| |_|/ |\___|\___|\__| |_| |_| |_|\___/ \___|_|\_\
//          |__/
//      _                           _                 _
//   __| | ___ _ __   ___ _ __   __| | ___ _ __   ___(_) ___  ___
//  / _` |/ _ \ '_ \ / _ \ '_ \ / _` |/ _ \ '_ \ / __| |/ _ \/ __|
// | (_| |  __/ |_) |  __/ | | | (_| |  __/ | | | (__| |  __/\__ \
//  \__,_|\___| .__/ \___|_| |_|\__,_|\___|_| |_|\___|_|\___||___/
//            |_|
var app = require("@/store/app.js");
var director = require("inject-loader!@/store/director.js");

var netInjector = require("inject-loader!@/store/net.js");
var net = netInjector({
  "../core/canon": Canon,
  "../core/p2p": p2p
});

//  _____         _
// |_   _|__  ___| |_ ___
//   | |/ _ \/ __| __/ __|
//   | |  __/\__ \ |_\__ \
//   |_|\___||___/\__|___/

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
