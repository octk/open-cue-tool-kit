import _ from "lodash";

export default {
  state: {
    cue: "",
    part: "",
    parts: "",
    production: null,
    actorsByPart: null
  },

  getters: {
    ACT_CUE(state) {
      return state.cue;
    },
    ACT_PART(state) {
      return state.part;
    },
    ACT_PARTS(state) {
      return state.parts;
    }
  },

  mutations: {
    ACT_SET_LINE_NUMBER(state, number) {
      state.lineNumber = number;
    },
    ACT_BUMP_CUE(state) {
      state.lineNumber += 1;
    },
    ACT_ADD_PRODUCTION(state, production) {
      state.productionsById[production.id] = production;
    },
    ACT_SET_ACTORS_BY_PART(state, actorsByPart) {
      state.actorsByPart = actorsByPart;
    },
    ACT_SET_CUES_AND_PARTS(state) {
      //Update which cue is current
      const line = state.script[state.lineNumber];
      const currentActor = state.actorsByPart[line.s];
      state.part = line.s;
      if (currentActor === state.identity) {
        state.cue = line.t;
      } else {
        state.cue = "";
      }

      // Update which parts actors will next play
      const speakerOrder = state.script.map(d => d.s);
      const pastSpeakers = speakerOrder.slice(0, state.lineNumber);
      const futureSpeakers = speakerOrder.slice(state.lineNumber);
      const nextToSpeak = futureSpeakers.concat(pastSpeakers);

      state.parts = _.sortBy(state.cast.partsByActor[state.identity], speaker =>
        nextToSpeak.indexOf(speaker)
      ).join(", ");
    }
  },

  actions: {
    ACT_START_PLAY({ commit }) {
      commit("ACT_SET_LINE_NUMBER", 0);
      commit("ACT_SET_CUES_AND_PARTS");
    },

    ACT_NEXT_CUE({ commit }) {
      commit("ACT_BUMP_CUE");
      commit("ACT_SET_CUES_AND_PARTS");
    },
    async ACT_SET_NAME({ state, commit }, name) {
      commit("APP_SET_ASPIRATION", "cueing");

      state.script = await state.canon.fetchScriptByTitle(
        state.production.title
      );
      state.identity = await state.comms.acceptInvite({
        ...state.production,
        name
      });
    },
    async ACT_ACCEPT_INVITE({ state, commit }, production) {
      state.production = production;
      commit("APP_SET_ASPIRATION", "naming");
    },
    ACT_CUE_NEXT_ACTOR({ state }) {
      state.comms.cueNextActor();
    },
    ACT_TOGGLE_AUTO_CAST({ state }) {
      state.autoCast = !state.autoCast;
    }
  }
};
