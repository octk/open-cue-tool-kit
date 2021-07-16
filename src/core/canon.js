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

    let remotePlays = [];
    try {
      const remoteTitles = await fetch(this.list);
      remotePlays = await Promise.all(
        remoteTitles.map(async title => {
          return { title, sections: this.sections(await fetch(title)) };
        })
      );
    } catch (error) {
      console.error(
        `Canon failed to load remote plays from ${this.list} `,
        error
      );
    }

    return [
      ...Object.entries(localPlays).map(([title, lines]) => ({
        title,
        sections: this.sections(lines)
      })),
      ...remotePlays
    ];
  }
  async fetchScriptByTitle({ title, section }) {
    let playsByTitle = await this.localPlays();
    let lines = [];
    if (playsByTitle[title]) {
      lines = playsByTitle[title];
    } else {
      lines = await fetch(title);
    }

    if (section !== "All") {
      lines = lines.filter(({ l: lineSection }) =>
        lineSection.startsWith(section)
      );
    }

    return lines;
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

  sections(lines) {
    let sections = { All: "All" };
    if (lines && !lines.title) {
      // FIXME s3 old format
      sections = {
        ...sections,
        ...lines.reduce((acc, { l: line }) => {
          const [act, scene] = line.split(".");
          acc[act] = `Act ${act}`;
          acc[act + "." + scene] = `Act ${act} Scene ${scene}`;
          return acc;
        }, {})
      };
    }
    return sections;
  }
}
