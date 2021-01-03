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

const client = new Net.Socket();
client.connect({ port: port, host: host }, function () {
    console.log("TCP connection established with the server.");
    client.write(JSON.stringify(lePacket3));
});

client.on("data", function (chunk) {
    console.log(`[Received]: ${chunk.toString()}.`);
    client.end();
});

client.on("end", function () {
    console.log("Requested an end to the TCP connection");
});
