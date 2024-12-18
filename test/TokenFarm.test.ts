import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";

describe("TokenFarm", function () {
  let owner: any;
  let user: any;
  let tokenFarm: any;
  let dappToken: any;
  let lpToken: any;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Desplegar el contrato DappToken y LPToken
    const DappToken = await ethers.getContractFactory("DappToken");
    dappToken = await DappToken.deploy();
    await dappToken.deployed();

    const LPToken = await ethers.getContractFactory("LPToken");
    lpToken = await LPToken.deploy();
    await lpToken.deployed();

    // Desplegar el contrato TokenFarm
    const TokenFarm = await ethers.getContractFactory("TokenFarm");
    tokenFarm = await TokenFarm.deploy(dappToken.address, lpToken.address);
    await tokenFarm.deployed();

    // Asignar tokens LP al usuario para depositar
    await lpToken.mint(user.address, ethers.utils.parseEther("1000"));
    await lpToken.connect(user).approve(tokenFarm.address, ethers.utils.parseEther("1000"));
  });

  it("should mint LP tokens and deposit them", async function () {
    const amount = ethers.utils.parseEther("100");
    await tokenFarm.connect(user).deposit(amount);

    // Verificar el balance después de la transacción
    const userBalance = await tokenFarm.stakingBalance(user.address);
    expect(userBalance.toString()).to.equal(amount.toString());
  });

  it("should distribute rewards correctly", async function () {
    const amount = ethers.utils.parseEther("100");
    await tokenFarm.connect(user).deposit(amount);

    // Simulamos la creación de un bloque
    await ethers.provider.send("evm_mine", []);

    // Llamamos a la función de distribución de recompensas
    await tokenFarm.connect(owner).distributeRewardsAll();

    // Verificamos que las recompensas calculadas sean las correctas
    const rewards = await tokenFarm.pendingRewards(user.address);
    const expectedReward = ethers.utils.parseEther("1"); // Ajusta el valor según el cálculo

    expect(rewards.toString()).to.equal(expectedReward.toString());
  });

  it("should allow users to claim rewards", async function () {
    const amount = ethers.utils.parseEther("100");
    await tokenFarm.connect(user).deposit(amount);

    // Simulamos la creación de bloques para acumular recompensas
    await ethers.provider.send("evm_mine", []);

    // Llamamos a la distribución de recompensas
    await tokenFarm.connect(owner).distributeRewardsAll();

    // Verificamos el balance de recompensas
    const userBalanceBefore = await dappToken.balanceOf(user.address);

    // Llamamos a claimRewards y verificamos que el balance aumente
    await tokenFarm.connect(user).claimRewards();

    const userBalanceAfter = await dappToken.balanceOf(user.address);
    const expectedReward = ethers.utils.parseEther("1"); // Este valor debe coincidir con el cálculo esperado de recompensas

    expect(userBalanceAfter.sub(userBalanceBefore).toString()).to.equal(expectedReward.toString());
  });

  it("should allow users to withdraw tokens and claim rewards", async function () {
    const amount = ethers.utils.parseEther("100");
    await tokenFarm.connect(user).deposit(amount);

    // Simulamos la creación de bloques para acumular recompensas
    await ethers.provider.send("evm_mine", []);

    // Llamamos a la distribución de recompensas
    await tokenFarm.connect(owner).distributeRewardsAll();

    // Llamamos a la función de retiro
    await tokenFarm.connect(user).withdraw();

    // Verificamos que el saldo de LP tokens del usuario haya aumentado
    const userLpBalance = await lpToken.balanceOf(user.address);
    expect(userLpBalance.toString()).to.equal(amount.toString()); // Comparar BigNumbers correctamente
  });
});

