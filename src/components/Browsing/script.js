import localForage from "localforage";
import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";

export default {
  name: "Browsing",
  components,
  data: () => ({ selectedPlay: null, downloadPlays: null }),
  computed: {
    ...mapGetters({
      availablePlays: "DIR_PLAYS"
    }),
    downloadLink() {
      if (this.downloadPlays) {
        return URL.createObjectURL(new Blob(this.downloadPlays));
      }
      return null;
    }
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
  },
  created: function() {
    const self = this;
    localForage
      .getItem("localPlays")
      .then(function(result) {
        self.downloadPlays = result;
      })
      .catch(function(err) {
        console.error(err);
      });
  }
};
