const Net = require("net");
const port = 13678;
const host = "localhost";

const lePacket1 = {
  type: "AddItem",
  payload: {
    name: "Headhunter",
    rarity: "Very Unique",
  },
};
const lePacket2 = {
  type: "Exit",
  payload: {},
};

const lePacket3 = {
  type: "FetchCharacter",
  payload: {
    accountName: "tris790",
    characterName: "MyMang",
  },
};

const lePacket4 = {
  type: "GetStats",
  payload: {
    accountName: "tris790",
    characterName: "MyMang",
    skillIndex: 7,
  },
};

const client = new Net.Socket();
client.connect({ port: port, host: host }, function () {
  console.log("TCP connection established with the server.");
  client.write(JSON.stringify(lePacket4));
});

client.on("data", function (chunk) {
  const json = JSON.parse(chunk);
  const pretty = JSON.stringify(json, null, 4);
  console.log(`[Received]: ${pretty}`);
  client.end();
});

client.on("end", function () {
  console.log("Requested an end to the TCP connection");
});
