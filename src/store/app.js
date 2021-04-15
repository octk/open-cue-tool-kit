import _ from "lodash";

export default {
  state: {
    aspiration: "starting",
    productionsById: {},
    actorsByPart: {},
    lineNumber: 0,
    cue: "",
    part: "",
    parts: "",
    production: null
  },
  getters: {
    APP_CUE(state) {
      return state.cue;
    },
    APP_PART(state) {
      return state.part;
    },
    APP_PARTS(state) {
      return state.parts;
    },
    APP_PARTS_BY_ACTOR(state) {
      if (!state.partsByActor) return {};
      return state.partsByActor;
    },
    APP_ACTORS_BY_PART(state) {
      if (!state.actorsByPart) return {};
      return state.actorsByPart;
    },
    APP_ASPIRATION(state) {
      return state.aspiration;
    },
    APP_INVITOR(state) {
      return state.invitor;
    },
    APP_PRODUCTIONS(state) {
      return _.values(state.productionsById);
    },
    APP_PLAY_NAME(state) {
      if (!state.production) return "(missing production title)";
      return state.production.title;
    }
  },
  mutations: {
    APP_SET_ASPIRATION(state, value) {
      state.aspiration = value;
    },
    APP_SET_LINE_NUMBER(state, number) {
      state.lineNumber = number;
    },
    APP_BUMP_CUE(state) {
      state.lineNumber += 1;
    },
    APP_ADD_PRODUCTION(state, production) {
      state.productionsById[production.id] = production;
    },
    APP_SET_ACTORS_BY_PART(state, actorsByPart) {
      state.actorsByPart = actorsByPart;

      // Also set partsByActor
      const partsByActor = {};
      _.forEach(actorsByPart, (actor, part) => {
        if (!partsByActor[actor]) {
          partsByActor[actor] = [];
        }
        partsByActor[actor].push(part);
      });
      state.partsByActor = partsByActor;
    },
    APP_SET_CUES_AND_PARTS(state) {
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

      state.parts = _.sortBy(state.partsByActor[state.identity], speaker =>
        nextToSpeak.indexOf(speaker)
      ).join(", ");
    }
  },
  actions: {
    async APP_INIT({ dispatch }) {
      await dispatch("NET_INIT");

      // Check for script in query params
      const params = new URLSearchParams(window.location.search);
      if (params.has("script")) {
        const script = params.get("script");
        await dispatch("DIR_LOAD_PLAY", JSON.parse(atob(script)));
      }
    },
    APP_START_PLAY({ commit }) {
      commit("APP_SET_LINE_NUMBER", 0);
      commit("APP_SET_CUES_AND_PARTS");
    },

    APP_NEXT_CUE({ commit }) {
      commit("APP_BUMP_CUE");
      commit("APP_SET_CUES_AND_PARTS");
    },
    async APP_SET_NAME({ state, commit, dispatch }, name) {
      commit("APP_SET_ASPIRATION", "cueing");

      state.script = state.production.lines;
      state.identity = await dispatch("NET_ACCEPT_INVITE", {
        ...state.production,
        name
      });
    },
    async APP_ACCEPT_INVITE({ state, commit }, production) {
      state.production = production;
      commit("APP_SET_ASPIRATION", "naming");
    },
    APP_CUE_NEXT_ACTOR({ dispatch }) {
      dispatch("NET_CUE_NEXT_ACTOR");
    }
  }
};
