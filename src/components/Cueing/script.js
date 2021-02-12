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
    ...mapGetters({ cue: "CUE", part: "PART", playName: "PLAY_NAME" })
  },
  methods: {
    ...mapActions({ cueNextActor: "CUE_NEXT_ACTOR" })
  }
};
