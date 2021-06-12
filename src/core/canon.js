import localForage from "localforage";
import bent from "bent";

const bucket = "https://macbeezy.s3.us-east-2.amazonaws.com/";
const fetch = bent(bucket, "json");

export default class Canon {
  constructor() {
    this.list = "play_list.json";
    this.db = "localPlays";
  }
  async loadScriptIndex() {
    const localPlays = await this.localPlays();

    let remoteTitles = [];
    try {
      remoteTitles = await fetch(this.list);
    } catch {
      console.error(`Canon failed to load remote plays from ${this.list} `);
    }

    return Object.keys(localPlays)
      .concat(remoteTitles)
      .map(title => ({ title }));
  }
  async fetchScriptByTitle(title) {
    let playsByTitle = await this.localPlays();
    if (playsByTitle[title]) {
      return playsByTitle[title];
    } else {
      return fetch(title);
    }
  }
  async addLocalScript({ title, lines }) {
    const plays = await this.localPlays();
    plays[title] = lines;
    localForage.setItem(this.db, plays);
  }

  async localPlays() {
    const plays = await localForage.getItem(this.db);
    return plays || {};
  }
}
