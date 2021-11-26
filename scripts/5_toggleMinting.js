module.exports = async function main(callback) {
  try {
    const NonFungibleZine = artifacts.require("NonFungibleZine");
    const contract = await NonFungibleZine.deployed();
    const mintingIsActive = await contract.mintingIsActive();
    console.log(`[+] Toggling mintingIsActive. Currently: ${mintingIsActive}`);
    if (mintingIsActive) {
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
