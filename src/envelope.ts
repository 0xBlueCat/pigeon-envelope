import { ethers } from "ethers";
import envelopeAbi from "../artifacts/contracts/PigeonEnvelope.sol/PigeonEnvelope.json";

export const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545/");
export const wallet = new ethers.Wallet(
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
).connect(provider);//envelope contract owner account

export const walletOperator = new ethers.Wallet(
    "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
).connect(provider);//category operator account

export const walletUser = new ethers.Wallet(
    "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e"
).connect(provider);//nft owner account

export const envelopeContractAddress = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707";

export const envelopCtr = new ethers.Contract(
  envelopeContractAddress,
  envelopeAbi.abi,
  provider
).connect(wallet);
export const envelopIface = new ethers.utils.Interface(envelopeAbi.abi);

export async function newCategory(
  operator: string,
  categoryName: string,
  baseUri: string
): Promise<string> {
  const tx = await envelopCtr.connect(wallet).newCategory(operator, categoryName, baseUri);
  console.log("newCategoryTxHash:", tx.hash);
  tx.wait();

  const rcp = await provider.getTransactionReceipt(tx.hash);
  const evt = await envelopIface.parseLog(rcp.logs[0]);
  console.log(
      "newCategoryEvt:",
      JSON.stringify(evt.args, undefined, 2)
  );
  return evt.args.categoryId;
}

export async function getTagClassId():Promise<string>{
  return await envelopCtr.getTagClassId();
}

export async function open(tokenId:string|number):Promise<void>{
  const tx = await envelopCtr.connect(walletUser).open(tokenId);
  console.log("openTxHash:", tx.hash);
  tx.wait();

  const rcp = await provider.getTransactionReceipt(tx.hash);
  const evt = await envelopIface.parseLog(rcp.logs[1]);
  console.log(
      "openEvt:",
      JSON.stringify(evt.args, undefined, 2)
  );
}

export async function hasOpened(tokenId:string |number ):Promise<boolean>{
  return await envelopCtr.hasOpened(tokenId);
}

export async function airdropEnvelopeNft(categoryId:string,addresses: string[]): Promise<string> {
  const maxFee = await provider.getGasPrice();
  const tx = await envelopCtr.connect(walletOperator).airdrop(categoryId, addresses, {
    maxFeePerGas: maxFee.mul(2),
    maxPriorityFeePerGas: maxFee,
  });
  console.log("TxHash:", tx.hash);
  tx.wait();
  let success = false;
  for (let i = 0; i < 15; i++) {
    try {
      await asyncSleep(5000);
      const rcp = await provider.getTransactionReceipt(tx.hash);
      console.log("Block:", rcp.blockNumber);
      success = true;
      break;
    } catch (e) {
      console.log(e);
    }
  }
  if (!success) {
    throw new Error("error: not completed");
  }
  return tx.hash;
}

export async function getEnvelopeTokenURI(tokeId: number): Promise<string> {
  return await envelopCtr.tokenURI(tokeId);
}

export function asyncSleep(timeout: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, timeout));
}

export async function ownerOf(tokenId: string | number): Promise<string> {
  return await envelopCtr.ownerOf(tokenId);
}
