import { mapActions, mapGetters } from "vuex";

import {
  IonButtons,
  IonContent,
  IonHeader,
  IonMenuButton,
  IonPage,
  IonTitle,
  IonToolbar
} from "@ionic/vue";
export default {
  name: "Cueing",
  components: {
    IonButtons,
    IonContent,
    IonHeader,
    IonMenuButton,
    IonPage,
    IonTitle,
    IonToolbar
  },
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
