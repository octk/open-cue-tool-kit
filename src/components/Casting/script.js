import { mapGetters } from "vuex";

import {
  IonButtons,
  IonContent,
  IonHeader,
  IonMenuButton,
  IonPage,
  IonTitle,
  IonToolbar,
  IonInput,
  IonLoading
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
    IonToolbar,
    IonInput,
    IonLoading
  },
  computed: {
    ...mapGetters({
      playName: "PLAY_NAME",
      invitationLink: "INVITATION_LINK",
      cast: "CAST"
    })
  }
};
