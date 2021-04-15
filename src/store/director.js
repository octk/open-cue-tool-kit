import castPlay from "../core/casting";
import { modalController } from "@ionic/vue";

export default {
  state: {
    plays: [],
    currentProductionId: null,
    currentTitle: null,
    invitationLink: "cuecannon.com/asdf",
    cast: null,
    actors: [],
    autoCast: true,
    manuallyCast: {},
    casting: null,
    begun: false,
    castingModal: null
  },

  getters: {
    DIR_PLAYS(state) {
      return state.plays;
    },
    DIR_PLAY_NAME(state) {
      return state.currentTitle;
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
    DIR_UNCAST_ROLES(state) {
      if (!state.cast) return [];
      const parts = Object.keys(state.cast.actorsByPart);
      const notInCasting = part => !state.cast.actorsByPart[part];
      return parts.filter(notInCasting);
    },
    DIR_CASTING(state) {
      return state.casting;
    },
    DIR_PARTS_BY_ACTOR(state) {
      if (!state.cast) return {};
      return state.cast.partsByActor;
    },
    DIR_ACTORS_BY_PART(state) {
      if (!state.cast) return {};
      return state.cast.actorsByPart;
    }
  },

  mutations: {
    DIR_BEGIN(state) {
      state.begun = true;
    },
    DIR_SET_PLAYS(state, plays) {
      state.plays = plays;
    },
    DIR_ADD_ACTOR(state, identity) {
      if (!state.begun) {
        state.actors.push(identity);
        state.cast = castPlay(
          state.script,
          state.actors,
          state.manuallyCast,
          state.autoCast
        );
      }
    }
  },

  actions: {
    async DIR_LOAD_PLAY({ state, commit, dispatch }, { title, lines }) {
      commit("APP_SET_ASPIRATION", "casting");
      state.currentTitle = title || "Untitled Play";
      state.script = lines;
      state.currentProduction = await dispatch("NET_MAKE_INVITE", {
        title: state.currentTitle,
        lines: state.script
      });
    },
    async DIR_SELECT_PLAY({ dispatch }, { title }) {
      const lines = await dispatch("NET_FETCH_SCRIPT", title);
      dispatch("DIR_LOAD_PLAY", { title, lines });
    },
    DIR_BROWSE_PLAYS({ commit }) {
      commit("APP_SET_ASPIRATION", "browsing");
    },
    DIR_SET_CASTING({ state }, casting) {
      state.casting = casting;
    },
    DIR_MANUAL_UPDATE_CAST({ state }, { role, actor }) {
      state.manuallyCast[role] = actor;
      state.cast = castPlay(
        state.script,
        state.actors,
        state.manuallyCast,
        state.autoCast
      );
    },
    DIR_BEGIN_SHOW({ dispatch, state, commit }) {
      commit("DIR_BEGIN");
      dispatch("NET_BEGIN_SHOW", state.cast);
    },
    DIR_INVITE_OPPORUNITY({ state, dispatch }) {
      if (state.currentProduction && !state.begun) {
        dispatch("NET_SHARE_PRODUCTION", state.currentProduction);
      }
    },
    DIR_TOGGLE_AUTO_CAST({ state }) {
      state.autoCast = !state.autoCast;
      state.cast = castPlay(
        state.script,
        state.actors,
        state.manuallyCast,
        state.autoCast
      );
    },
    async DIR_DEPLOY_CASTING_MODAL({ state }, component) {
      if (!state.begun) {
        state.castingModalController = await modalController.create(component);
        state.castingModalController.present();
      }
    },
    async DIR_DISMISS_CASTING_MODAL({ state }) {
      if (state.castingModalController) {
        state.castingModalController.dismiss();
      }
    }
  }
};
