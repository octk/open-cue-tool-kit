import { expect } from "chai";

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

/* eslint-disable no-unused-vars */
import app, {
  actions as app_actions,
  mutations as app_mutations,
  getters as app_getters
} from "@/store/app.js";
import director, {
  actions as dir_actions,
  mutations as dir_mutations,
  getters as dir_getters
} from "@/store/director.js";
/* eslint-enable no-unused-vars */

//  _____         _
// |_   _|__  ___| |_ ___
//   | |/ _ \/ __| __/ __|
//   | |  __/\__ \ |_\__ \
//   |_|\___||___/\__|___/

describe("casting", () => {
  it("casts an actor when added", () => {
    const store = {
      actors: [],
      manuallyCast: {},
      autoCast: true,
      casting: null,
      script: [{ l: "Who dis", s: "xxx" }]
    };
    const { DIR_ADD_ACTOR } = dir_mutations;
    const identity = { name: "Fred", identity: "pqwoenpadskfvnapsoitq" };
    DIR_ADD_ACTOR(store, identity);
    const { partsByActor } = store.cast;
    expect(partsByActor).to.have.property(identity.identity);
  });
});

describe("uncast", () => {
  const store = {};
  it("initially returns []", () => {
    const { DIR_UNCAST_ROLES } = dir_getters;
    expect(DIR_UNCAST_ROLES(store)).to.be.an("array").that.is.empty;
  });
  // it("has no uncast after casting");
  // it("has uncast roles on starting");
  // it("has uncast actors on joining");
});
