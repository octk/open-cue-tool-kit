import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";

export default {
  name: "Browsing",
  components,
  data: () => ({ selectedPlay: null }),
  computed: {
    ...mapGetters({
      availablePlays: "DIR_PLAYS"
    })
  },
  methods: {
    selectPlay(play) {
      this.selectedPlay = play;
    },
    deselectPlay() {
      this.selectedPlay = null;
    },
    selectSection(section) {
      this.directPlay({ ...this.selectedPlay, section });
    },
    ...mapActions({
      directPlay: "DIR_SELECT_PLAY"
    })
  }
};
