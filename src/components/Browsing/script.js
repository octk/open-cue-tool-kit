import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";

export default {
  name: "Browsing",
  components,
  data: () => ({ selectedPlay: null }),
  computed: {
    ...mapGetters({
      availablePlays: "DIR_PLAYS"
    }),
    availableSections() {
      if (!this.selectedPlay) return [];
      const sections = this.selectedPlay.lines.reduce((acc, { l: line }) => {
        const [act, scene] = line.split(".");
        acc[act] = `Act ${act}`;
        acc[scene] = `Act ${act} Scene ${scene}`;
        return acc;
      }, {});
      sections["All"] = "All"; // Whole play
      return sections;
    }
  },
  methods: {
    selectPlay(play) {
      this.selectedPlay = play;
    },
    deselectPlay() {
      this.selectPlay = null;
    },
    selectSection(section) {
      this.directPlay(this.selectedPlay, section);
    },
    ...mapActions({
      directPlay: "DIR_SELECT_PLAY"
    })
  }
};
