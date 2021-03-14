import _ from "lodash";

import Comms from "../net";
import Canon from "../core/canon";

import midsummerAct3 from "../../midsummer3.json";
import castPlay from "../core/casting";

export default {
  state: {
    // General model
    comms: null,
    canon: new Canon(),
    aspiration: "starting",
    plays: [{ title: "Midsummer Act 3" }],
    productionsById: {},
    script: midsummerAct3,
    actorsByPart: {},

    // Director model
    currentProductionId: null,
    invitationLink: "cuecannon.com/asdf",
    cast: null,
    actors: [],
    lineNumber: 0,
    autoCast: true,
    manuallyCast: {},
    casting: null,

    // Actor model
    cue: "",
    part: ""
  },
  getters: {
    PLAY_NAME(state) {
      return _.get(state, `productionsById.${state.currentProductionId}.title`);
    },
    INVITATION_LINK(state) {
      return state.invitationLink;
    },
    PARTS_BY_ACTOR(state) {
      if (!state.cast) return {};
      return state.cast.partsByActor;
    },
    ACTORS_BY_PART(state) {
      if (!state.cast) return {};
      return state.cast.actorsByPart;
    },
    ASPIRATION(state) {
      return state.aspiration;
    },
    INVITOR(state) {
      return state.invitor;
    },
    PLAYS(state) {
      return state.plays;
    },
    PRODUCTIONS(state) {
      return _.values(state.productionsById);
    },
    CUE(state) {
      return state.cue;
    },
    PART(state) {
      return state.part;
    },
    AUTO_CAST(state) {
      return state.autoCast;
    },
    UNCAST_ACTORS(state) {
      if (!state.cast) return [];
      const notInCasting = a =>
        !state.cast.partsByActor[a] || !state.cast.partsByActor[a].length;
      return state.actors.filter(notInCasting);
    },
    // UNCAST_ROLES FIXME
    CASTING(state) {
      return state.casting;
    }
  },
  mutations: {
    SET_ASPIRATION(state, value) {
      state.aspiration = value;
    }
  },
  actions: {
    //General actions
    async INIT({ dispatch }) {
      dispatch("LOAD_SCRIPTS");
      dispatch("INIT_COMMS");
    },

    async LOAD_SCRIPTS({ state }) {
      const response = await state.canon.loadScriptIndex();
      state.plays = response.map(title => ({ title }));
    },

    async INIT_COMMS({ state }) {
      state.comms = new Comms();

      // Director listeners
      state.comms.onAcceptInvite = function({ identity }) {
        state.actors.push(identity);
        state.cast = castPlay(state.script, state.actors, state.manuallyCast);
      };
      state.comms.onBeginShow = function({ actorsByPart }) {
        state.actorsByPart = actorsByPart;
        state.lineNumber = 0;
        setCues();
      };
      state.comms.onNewActor = function() {
        setTimeout(function() {
          // Delay while actor sets listeners
          if (state.aspiration === "casting") {
            const castingProduction =
              state.productionsById[state.currentProductionId];
            if (castingProduction) {
              state.comms.shareProduction(castingProduction);
            }
          }
        }, 5000);
      };

      // Actor listeners
      state.comms.onShareProduction = function(production) {
        state.productionsById[production.id] = production;
      };

      state.comms.onCueNextActor = function() {
        state.lineNumber += 1;
        setCues();
      };

      function setCues() {
        const line = state.script[state.lineNumber];
        const currentActor = state.actorsByPart[line.s];
        state.part = line.s;
        if (currentActor === state.identity) {
          state.cue = line.t;
        } else {
          state.cue = "";
        }
      }

      await state.comms.init();
    },

    // Director actions
    async SELECT_PLAY({ state }, play) {
      state.aspiration = "casting";
      state.cast = [];
      state.script = await state.canon.fetchScriptByTitle(play.title);

      const production = await state.comms.makeInvite(play.title);
      state.currentProductionId = production.id;
      state.productionsById[state.currentProductionId] = production;
    },
    MAKE_NEW_PRODUCTION({ state }) {
      state.aspiration = "browsing";
    },
    SET_CASTING({ state }, casting) {
      state.casting = casting;
    },
    MANUAL_UPDATE_CAST({ state }, { role, actor }) {
      state.manuallyCast[role] = actor;
      console.log(JSON.stringify(state.manuallyCast));
      state.cast = castPlay(state.script, state.actors, state.manuallyCast);
    },
    BEGIN_SHOW({ state }) {
      state.comms.beginShow(state.cast);
    },

    // Actor actions
    async ACCEPT_INVITE({ state }, production) {
      state.aspiration = "cueing";
      state.script = await state.canon.fetchScriptByTitle(production.title);
      state.identity = await state.comms.acceptInvite(production);
    },
    CUE_NEXT_ACTOR({ state }) {
      state.comms.cueNextActor();
    },
    TOGGLE_AUTO_CAST({ state }) {
      state.autoCast = !state.autoCast;
    }
  }
};
