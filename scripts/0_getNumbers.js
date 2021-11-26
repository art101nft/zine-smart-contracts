module.exports = async function main(callback) {
  try {
    const NonFungibleZine = artifacts.require("NonFungibleZine");
    const contract = await NonFungibleZine.deployed();
    const existingPrime = (await contract.randPrime()).toString();
    const existingTimestamp = (await contract.timestamp()).toString();
    console.log(`randPrime: ${existingPrime}`);
    console.log(`timestamp: ${existingTimestamp}`);
    console.log(`contract address: ${contract.address}`);
    console.log(`baseURI: ${await contract.baseURI()}`);
    callback(0);
  } catch (error) {
    console.error(error);
    callback(1);
  }
}
