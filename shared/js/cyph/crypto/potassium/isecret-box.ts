/** Equivalent to sodium.crypto_secretbox. */
export interface ISecretBox {
	/** Additional data length. */
	readonly aeadBytes: number;

	/** Key length. */
	readonly keyBytes: number;

	/** Generates a new nonce. */
	newNonce (size: number) : Uint8Array;

	/** Decrypts cyphertext. */
	open (
		cyphertext: Uint8Array,
		key: Uint8Array,
		additionalData?: Uint8Array
	) : Promise<Uint8Array>;

	/** Encrypts plaintext. */
	seal (
		plaintext: Uint8Array,
		key: Uint8Array,
		additionalData?: Uint8Array
	) : Promise<Uint8Array>;
}
