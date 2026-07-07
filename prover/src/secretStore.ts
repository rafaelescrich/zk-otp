import type { Address } from "viem";
import { commitmentFor, randomFieldElement } from "./poseidon.js";
import { registrationBinding } from "./actionHash.js";

export interface RegistrationDomain {
  account: Address;
  chainId: bigint;
}

export interface SecretStore {
  generate(domain: RegistrationDomain): Promise<{ commitment: bigint; bindingHash: bigint }>;
  getWitness(): Promise<{ secret: bigint; salt: bigint }>;
  replace(secret: bigint, salt: bigint): Promise<void>;
  isInitialized(): Promise<boolean>;
}

export class MemorySecretStore implements SecretStore {
  #secret?: bigint;
  #salt?: bigint;

  async generate(domain: RegistrationDomain): Promise<{ commitment: bigint; bindingHash: bigint }> {
    this.#secret = randomFieldElement();
    this.#salt = randomFieldElement();

    const commitment = await commitmentFor(this.#secret, this.#salt);
    return {
      commitment,
      bindingHash: registrationBinding({
        commitment,
        account: domain.account,
        chainId: domain.chainId
      })
    };
  }

  async getWitness(): Promise<{ secret: bigint; salt: bigint }> {
    if (this.#secret === undefined || this.#salt === undefined) {
      throw new Error("secret store is not initialized");
    }
    return { secret: this.#secret, salt: this.#salt };
  }

  async replace(secret: bigint, salt: bigint): Promise<void> {
    this.#secret = secret;
    this.#salt = salt;
  }

  async isInitialized(): Promise<boolean> {
    return this.#secret !== undefined && this.#salt !== undefined;
  }
}
