import _ from "lodash";

import Comms from "../net";
import midsummerAct3 from "../../midsummer3.json";
import castPlay from "../core/casting";
import Canon from "../core/canon";
const canon = new Canon();

export default {
  state: {
    // These are for everyone
    comms: null,
    productions: [],
    plays: [{ title: "Midsummer Act 3" }],
    aspiration: "starting",
    actorsByPart: {},

    // These are for someone running a production
    playName: "Midsummer Act 3",
    invitationLink: "cuecannon.com/asdf",
    cast: [],
    casting: null,
    castMembers: [],
    lineNumber: 0,

    // These are for someone joining a production
    cue: "",
    part: "",
    script: midsummerAct3
  },
  getters: {
    PLAY_NAME(state) {
      return state.playName;
    },
    INVITATION_LINK(state) {
      return state.invitationLink;
    },
    CAST(state) {
      return state.cast;
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
      return state.productions;
    },
    CUE(state) {
      return state.cue;
    },
    PART(state) {
      return state.part;
    }
  },
  mutations: {
    SET_ASPIRATION(state, value) {
      state.aspiration = value;
    }
  },
  actions: {
    async SELECT_PLAY({ state }, play) {
      state.playName = play.title;
      state.aspiration = "casting";
      state.cast = [];
      state.script = await canon.fetchScriptByTitle(play.title);

      const id = state.comms.makeInvite(play.title);
      state.productions.push({ id, title: play.title });
    },
    MAKE_NEW_PRODUCTION({ state }) {
      state.aspiration = "browsing";
    },
    INIT({ dispatch }) {
      dispatch("LOAD_SCRIPTS");
      dispatch("INIT_COMMS");
    },

    async LOAD_SCRIPTS({ state }) {
      const response = await canon.loadScriptIndex();
      state.plays = response.map(title => ({ title }));
    },

    INIT_COMMS({ state }) {
      state.comms = new Comms();
      state.comms.onNewProduction = function(production) {
        state.productions.push(production);
      };
      state.comms.onAcceptInvite = function({ identity }) {
        console.log(arguments);
        state.castMembers.push(identity);
        state.casting = castPlay(state.script, state.castMembers);
        state.cast = _.map(state.casting.partsByActor, (parts, actor) => ({
          name: actor,
          roles: parts
        }));
      };
      state.comms.onBeginShow = function({ actorsByPart }) {
        state.actorsByPart = actorsByPart;
        state.lineNumber = 0;
        setCues();
      };

      state.comms.onCueNextActor = function() {
        state.lineNumber += 1;
        setCues();
      };

      function setCues() {
        const line = state.script[state.lineNumber];
        const currentActor = state.actorsByPart[line.s];
        if (currentActor === state.identity) {
          state.part = line.s;
          state.cue = line.t;
        } else {
          state.cue = "";
        }
      }

      state.comms.init();
    },

    // Production communication
    async ACCEPT_INVITE({ state }, production) {
      state.aspiration = "cueing";
      state.script = await canon.fetchScriptByTitle(production.title);
      state.playName = production.title;
      state.identity = await state.comms.acceptInvite(production);
    },
    BEGIN_SHOW({ state }) {
      state.comms.beginShow(state.casting);
    },
    CUE_NEXT_ACTOR({ state }) {
      state.comms.cueNextActor();
    }
  }
};
