import * as components from "@ionic/vue";
import { mapGetters, mapActions } from "vuex";
import QRCode from "qrcode";

export default {
  name: "Casting",
  components,
  data: () => ({
    autoCast: true
  }),
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
    ...mapActions({ beginShow: "BEGIN_SHOW" }),
    copyInvitationLink() {
      navigator.clipboard.writeText(this.invitationLink);
    }
  }
};
