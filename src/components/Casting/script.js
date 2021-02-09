import { mapGetters } from "vuex";

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
  name: "Casting",
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
    ...mapGetters({ playName: "PLAY_NAME" })
  }
};
