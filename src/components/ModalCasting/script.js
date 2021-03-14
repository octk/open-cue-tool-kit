import _ from "lodash";
import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";

export default {
  name: "Modal",
  components,
  computed: {
    ...mapGetters({
      casting: "CASTING",
      cast: "ACTORS",
      actorsByPart: "ACTORS_BY_PART",
      partsByActor: "PARTS_BY_ACTOR"
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
      select: "MANUAL_UPDATE_CAST"
    })
  }
};
