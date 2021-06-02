import { expect } from "chai";
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

//   ____          _   _
//  / ___|__ _ ___| |_(_)_ __   __ _
// | |   / _` / __| __| | '_ \ / _` |
// | |__| (_| \__ \ |_| | | | | (_| |
//  \____\__,_|___/\__|_|_| |_|\__, |
//                             |___/

describe("casting", () => {
  const { DIR_ADD_ACTOR } = dir_mutations;
  it("casts an actor when added", () => {
    const store = {
      actors: [],
      manuallyCast: {},
      autoCast: true,
      script: [{ l: "Who dis", s: "Juliet" }]
    };
    const identity = { name: "Fred", identity: "pqwoenpadskfvnapsoitq" };
    DIR_ADD_ACTOR(store, identity);
    const { partsByActor } = store.cast;
    expect(partsByActor).to.have.property(identity.identity);
  });
  it("casts a part when actor added", () => {
    it("casts an actor when added", () => {
      const store = {
        actors: [],
        manuallyCast: {},
        autoCast: true,
        script: [{ l: "Who dis", s: "Juliet" }]
      };
      const identity = { name: "Fred", identity: "pqwoenpadskfvnapsoitq" };
      DIR_ADD_ACTOR(store, identity);
      const { actorsByPart } = store.cast;
      expect(actorsByPart).to.have.property("Juliet");
    });
  });
  it("skips autocasting an actor when added", () => {
    const store = {
      actors: [],
      manuallyCast: {},
      autoCast: false,
      script: [{ l: "Who dis", s: "Juliet" }]
    };
    const identity = { name: "Fred", identity: "pqwoenpadskfvnapsoitq" };
    DIR_ADD_ACTOR(store, identity);
    const { partsByActor } = store.cast;
    expect(partsByActor[identity.identity]).to.be.an("array").that.is.empty;
  });
  it("casts a part when actor added", () => {
    it("casts an actor when added", () => {
      const store = {
        actors: [],
        manuallyCast: {},
        autoCast: false,
        script: [{ l: "Who dis", s: "Juliet" }]
      };
      const identity = { name: "Fred", identity: "pqwoenpadskfvnapsoitq" };
      DIR_ADD_ACTOR(store, identity);
      const { actorsByPart } = store.cast;
      expect(actorsByPart).to.not.have.property("Juliet");
    });
  });
});

//  _   _                     _
// | | | |_ __   ___ __ _ ___| |_
// | | | | '_ \ / __/ _` / __| __|
// | |_| | | | | (_| (_| \__ \ |_
//  \___/|_| |_|\___\__,_|___/\__|
//

describe("uncast", () => {
  const { DIR_UNCAST_ACTORS } = dir_getters;
  const { DIR_ADD_ACTOR } = dir_mutations;
  it("initially returns []", () => {
    const store = {};
    expect(DIR_UNCAST_ACTORS(store)).to.be.an("array").that.is.empty;
  });
  it("sees an actor just added", () => {
    const store = {
      actors: [],
      manuallyCast: {},
      autoCast: false,
      script: [{ l: "Who dis", s: "Juliet" }]
    };
    const identity = { name: "Fred", identity: "pqwoenpadskfvnapsoitq" };
    DIR_ADD_ACTOR(store, identity);
    expect(DIR_UNCAST_ACTORS(store)[0]).to.equal(identity);
  });
});
