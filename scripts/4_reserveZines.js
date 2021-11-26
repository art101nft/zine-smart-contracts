module.exports = async function main(callback) {
  try {
    const NonFungibleZine = artifacts.require("NonFungibleZine");
    const contract = await NonFungibleZine.deployed();
    await contract.reserveZines();
    console.log(`Minted reserved zines to contract deployer`);
    callback(0);
  } catch (error) {
    console.error(error);
    callback(1);
  }
}
