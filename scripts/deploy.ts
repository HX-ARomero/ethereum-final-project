import { ethers } from "hardhat";

async function main() {
  // Desplegar el contrato DappToken
  const DappToken = await ethers.getContractFactory("DappToken"); // Cambiado a "DappToken"
  const dappToken = await DappToken.deploy();
  await dappToken.deployed();
  console.log(`DappToken desplegado en: ${dappToken.address}`);

  // Desplegar el contrato LPToken
  const LPToken = await ethers.getContractFactory("LPToken");
  const lpToken = await LPToken.deploy();
  await lpToken.deployed();
  console.log(`LPToken desplegado en: ${lpToken.address}`);

  // Desplegar el contrato TokenFarm
  const TokenFarm = await ethers.getContractFactory("TokenFarm");
  const tokenFarm = await TokenFarm.deploy(dappToken.address, lpToken.address);
  await tokenFarm.deployed();
  console.log(`TokenFarm desplegado en: ${tokenFarm.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
