import { mapActions, mapGetters } from "vuex";
import * as components from "@ionic/vue";

export default {
  name: "Cueing",
  components,
  computed: {
    ...mapGetters({
      cue: "APP_CUE",
      part: "APP_PART",
      playName: "APP_PLAY_NAME",
      parts: "APP_PARTS",
      partsByActor: "APP_PARTS_BY_ACTOR"
    })
  },
  methods: {
    ...mapActions({ cueNextActor: "APP_CUE_NEXT_ACTOR" })
  }
};
