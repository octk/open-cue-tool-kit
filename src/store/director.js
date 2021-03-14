import _ from "lodash";
import castPlay from "../core/casting";

export default {
  state: {
    plays: [{ title: "Midsummer Act 3" }],
    currentProductionId: null,
    invitationLink: "cuecannon.com/asdf",
    cast: null,
    actors: [],
    lineNumber: 0,
    autoCast: true,
    manuallyCast: {},
    casting: null
  },

  getters: {
    DIR_PLAYS(state) {
      return state.plays;
    },
    DIR_PLAY_NAME(state) {
      return _.get(state, `productionsById.${state.currentProductionId}.title`);
    },
    DIR_ACTORS(state) {
      return state.actors;
    },
    DIR_INVITATION_LINK(state) {
      return state.invitationLink;
    },
    DIR_AUTO_CAST(state) {
      return state.autoCast;
    },
    DIR_UNCAST_ACTORS(state) {
      if (!state.cast) return [];
      const notInCasting = ({ identity }) =>
        !state.cast.partsByActor[identity] ||
        !state.cast.partsByActor[identity].length;
      return state.actors.filter(notInCasting);
    },
    // UNCAST_ROLES FIXME
    DIR_CASTING(state) {
      return state.casting;
    }
  },

  mutations: {
    DIR_SET_PLAYS(state, plays) {
      state.plays = plays;
    },
    DIR_ADD_ACTOR(state, identity) {
      state.actors.push(identity);
      state.cast = castPlay(state.script, state.actors, state.manuallyCast);
    }
  },

  actions: {
    async DIR_SELECT_PLAY({ state, commit }, play) {
      commit("APP_SET_ASPIRATION", "casting");
      state.cast = [];
      state.script = await state.canon.fetchScriptByTitle(play.title);

      const production = await state.comms.makeInvite(play.title);
      state.currentProductionId = production.id;
      state.productionsById[state.currentProductionId] = production;
    },
    DIR_MAKE_NEW_PRODUCTION({ commit }) {
      commit("APP_SET_ASPIRATION", "browsing");
    },
    DIR_SET_CASTING({ state }, casting) {
      state.casting = casting;
    },
    DIR_MANUAL_UPDATE_CAST({ state }, { role, actor }) {
      state.manuallyCast[role] = actor;
      state.cast = castPlay(state.script, state.actors, state.manuallyCast);
    },
    DIR_BEGIN_SHOW({ dispatch, state }) {
      dispatch("NET_BEGIN_SHOW", state.cast);
    },
    DIR_INVITE_OPPORUNITY({ state, dispatch }) {
      if (state.productionsById) {
        const castingProduction =
          state.productionsById[state.currentProductionId];
        if (castingProduction) {
          dispatch("NET_SHARE_PRODUCTION", castingProduction);
        }
      }
    }
  }
};
