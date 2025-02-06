const [encoder, decoder] = [new TextEncoder(), new TextDecoder()];
const algorithm = {
	name: "RSA-OAEP"
};
const keyParams = {
	...algorithm,
	hash: "SHA-256"
};
const rsaParams = {
	...keyParams,
	modulusLength: 4096,
	publicExponent: new Uint8Array([1, 0, 1])
};
const keyPair = await crypto.subtle.generateKey(rsaParams, true, ["encrypt", "decrypt"]);
const privateKeyString = JSON.stringify(await crypto.subtle.exportKey("jwk", keyPair.privateKey));
const publicKeyString = JSON.stringify(await crypto.subtle.exportKey("jwk", keyPair.publicKey));
const encrypt = async (publicKey, value) => {
	const key = await crypto.subtle.importKey("jwk", JSON.parse(publicKey), keyParams, true, ["encrypt"]);
	const decoded = btoa(new Uint8Array(await crypto.subtle.encrypt(algorithm, key, encoder.encode(value))));
	return decoded;
};
const decrypt = async (privateKey, value) => {
	const key = await crypto.subtle.importKey("jwk", JSON.parse(privateKey), keyParams, true, ["decrypt"]);
	const decoded = decoder.decode(new Uint8Array(await crypto.subtle.decrypt(algorithm, key, Uint8Array.from(atob(value).split(",")))));
	return decoded;
};
const input = "test";
const encrypted = await encrypt(publicKeyString, input);
const decrypted = await decrypt(privateKeyString, encrypted);
console.log(input, encrypted, decrypted);