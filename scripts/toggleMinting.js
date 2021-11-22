module.exports = async function main(callback) {
  try {
    const NonFungibleZine = artifacts.require("NonFungibleZine");
    const contract = await NonFungibleZine.deployed();
    const mintingActive = await contract.mintingActive();
    console.log(`[+] Toggling mintingActive. Currently: ${mintingActive}`);
    if (mintingActive) {
      await contract.toggleMinting();
      console.log(`Minting disabled!`);
    } else {
      await contract.toggleMinting();
      console.log(`Minting enabled!`);
    }
    callback(0);
  } catch (error) {
    console.error(error);
    callback(1);
  }
}
