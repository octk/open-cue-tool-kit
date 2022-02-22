import _ from "lodash";
import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";

export default {
  name: "Modal",
  components,
  computed: {
    ...mapGetters({
      casting: "DIR_CASTING",
      cast: "DIR_ACTORS",
      actorsByPart: "DIR_ACTORS_BY_PART",
      partsByActor: "DIR_PARTS_BY_ACTOR"
    }),
    roles() {
      if (!this.actorsByPart) return [];
      return Object.keys(this.actorsByPart);
    },
    actors() {
      if (!this.partsByActor) return [];
      return Object.keys(this.partsByActor);
    },
    actorNamesByActorId() {
      if (!this.cast) return {};
      return _.keyBy(this.cast, "identity");
    }
  },
  methods: {
    ...mapActions({
      select: "DIR_MANUAL_UPDATE_CAST",
      dismiss: "DIR_DISMISS_CASTING_MODAL"
    }),
    selectAndDismiss(selection) {
      this.select(selection);
      this.dismiss();
    }
  }
};
