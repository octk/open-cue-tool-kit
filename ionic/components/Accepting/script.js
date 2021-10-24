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
    ...mapGetters({
      invitor: "INVITOR",
      playName: "PLAY_NAME"
    })
  },
  methods: {
    joinInvitation() {
      console.log("joinInvitation not implemented");
    }
  }
};
