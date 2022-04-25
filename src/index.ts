import {
  airdropEnvelopeNft,
  envelopIface,
  hasOpened,
  newCategory,
  open,
  provider,
  walletOperator,
  walletUser
} from "./envelope";

const nconf = require("nconf");

async function airdrops(categoryId:string):Promise<void>{
  const whiteList = (await nconf
      .file("./whiteList.json")
      .get("whiteList")) as string[];

  const batch = 200;
  for (let i = 0; i < whiteList.length / batch; i++) {
    let from = i * batch;
    let to = (i + 1) * batch;
    if (to >= whiteList.length) {
      to = whiteList.length;
    }
    console.log(
        `Start batchNo:${i} [from:${from} to:${to}) Total:${whiteList.length}`
    );
    const addresses = whiteList.slice(from, to);
    await airdropEnvelopeNft(categoryId, addresses);

    console.log(`End batchNo:${i}\n`);
  }
  console.log("completed");
}

async function main(): Promise<void> {
  const categoryId = await newCategory(await walletOperator.getAddress(), "xxx2", "xxx");
  const airdropTxHash = await airdropEnvelopeNft(categoryId, [await walletUser.getAddress()]);
  const rcp = await provider.getTransactionReceipt(
      airdropTxHash
  )
  const evt  = await envelopIface.parseLog(rcp.logs[1])
  console.log("AirdropEvt:", JSON.stringify(evt.args, undefined, 2));
  const tokenId = evt.args.tokenId;
  console.log("HasOpened:",  await hasOpened(tokenId));
  await open(tokenId);
  console.log("HasOpened:", await hasOpened(tokenId));
}

void main();
