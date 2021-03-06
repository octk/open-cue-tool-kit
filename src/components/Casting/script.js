import * as vue from "@ionic/vue";
import Modal from "../ModalCasting";
import { mapGetters, mapActions } from "vuex";
import QRCode from "qrcode";

export default {
  name: "Casting",
  components: { ...vue, Modal },
  computed: {
    ...mapGetters({
      playName: "PLAY_NAME",
      invitationLink: "INVITATION_LINK",
      cast: "CAST",
      uncast: "UNCAST",
      autoCast: "AUTO_CAST"
    })
  },
  mounted() {
    const canvas = document.getElementById("qrCanvas");
    QRCode.toCanvas(canvas, this.invitationLink, function(error) {
      if (error) console.error(error);
    });
  },
  methods: {
    ...mapActions({
      beginShow: "BEGIN_SHOW",
      toggleAutoCast: "TOGGLE_AUTO_CAST"
    }),
    copyInvitationLink() {
      navigator.clipboard.writeText(this.invitationLink);
    },
    async castingModal() {
      const modal = await vue.modalController.create({
        component: Modal
      });
      return modal.present();
    }
  }
};
