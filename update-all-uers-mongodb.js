const crypto = require("crypto");
use("quip-db");
const generateKeys = async () => {
	const keyPair = await crypto.subtle.generateKey(
		{
			name: "RSA-OAEP",
			modulusLength: 4096,
			publicExponent: new Uint8Array([1, 0, 1]),
			hash: "SHA-256"
		},
		true,
		["encrypt", "decrypt"]
	);
	const privateKey = JSON.stringify(await crypto.subtle.exportKey("jwk", keyPair.privateKey));
	const publicKey = JSON.stringify(await crypto.subtle.exportKey("jwk", keyPair.publicKey));
	return [privateKey, publicKey];
};
db.users.find({}).forEach(async function (doc) {
	const [privateKey, publicKey] = await generateKeys();
	db.users.updateOne(
		{ _id: doc._id },
		{
			$unset: {
				privateKey,
				publicKey
			}
		}
	);
});