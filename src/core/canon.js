import bent from "bent";

const bucket = "https://macbeezy.s3.us-east-2.amazonaws.com/";
const fetch = bent(bucket, "json");

export default class Canon {
  constructor() {
    this.list = "play_list.json";
  }
  loadScriptIndex() {
    return fetch(this.list);
  }
  fetchScriptByTitle(title) {
    return fetch(title);
  }
}
