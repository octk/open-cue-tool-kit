import { mapGetters } from "vuex";
import QRCode from "qrcode";

import {
  IonButtons,
  IonContent,
  IonHeader,
  IonMenuButton,
  IonPage,
  IonTitle,
  IonToolbar,
  IonInput,
  IonLoading,
  IonList,
  IonItem,
  IonItemOptions,
  IonItemOption
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
    IonLoading,
    IonList,
    IonItem,
    IonItemOptions,
    IonItemOption
  },
  computed: {
    ...mapGetters({
      playName: "PLAY_NAME",
      invitationLink: "INVITATION_LINK",
      cast: "CAST"
    })
  },
  mounted() {
    const canvas = document.getElementById("qrCanvas");
    QRCode.toCanvas(canvas, this.invitationLink, function(error) {
      if (error) console.error(error);
    });
  },
  methods: {
    copyInvitationLink() {
      navigator.clipboard.writeText(this.invitationLink);
    }
  }
};
