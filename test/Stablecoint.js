import { expect } from "chai";
import hardhat from "hardhat"

const { ethers } = hardhat;

describe("StableCoin", function () {
    async function deployFixture() {
        const [owner, user, liquidator] = await ethers.getSigners();

        // Deploy Oracle
        const Oracle = await ethers.getContractFactory("Oracle");
        const oracle = await Oracle.deploy();
        await oracle.waitForDeployment();

        // Set ETH price = 2000 USD
        await oracle.setEthPrice(ethers.parseEther("2000"));

        // Deploy StableCoin
        const StableCoin = await ethers.getContractFactory("StableCoin");
        const stable = await StableCoin.deploy();
        await stable.waitForDeployment();

        // Register oracle
        await stable.registerOracle(await oracle.getAddress());

        return { stable, oracle, owner, user, liquidator };
    }

    // ORACLE 
    it("registerOracle: sets oracle address (success)", async () => {
        const { stable, oracle } = await deployFixture();
        expect(await stable.oracle()).to.equal(await oracle.getAddress());
    });

    // DEPOSIT
    it("deposit: accepts ETH collateral (success)", async () => {
        const { stable, user } = await deployFixture();

        await stable.connect(user).deposit({ value: ethers.parseEther("1") });

        expect(await stable.ethDeposits(user.address)).to.equal(
            ethers.parseEther("1")
        );
    });

    it("deposit: reverts on zero ETH (failure)", async () => {
        const { stable, user } = await deployFixture();

        await expect(
            stable.connect(user).deposit({ value: 0 })
        ).to.be.revertedWith("No ETH sent");
    });

    // WITHDRAW
    it("withdraw: withdraws ETH if position healthy (success)", async () => {
        const { stable, user } = await deployFixture();

        await stable.connect(user).deposit({ value: ethers.parseEther("1") });
        await stable.connect(user).withdraw(ethers.parseEther("0.5"));

        expect(await stable.ethDeposits(user.address)).to.equal(
            ethers.parseEther("0.5")
        );
    });

    it("withdraw: reverts if collateral insufficient (failure)", async () => {
        const { stable, user } = await deployFixture();

        await expect(
            stable.connect(user).withdraw(ethers.parseEther("1"))
        ).to.be.revertedWith("Insufficient collateral");
    });

    // MINT
    it("mint: mints SBC within collateral limit (success)", async () => {
        const { stable, user } = await deployFixture();

        // 1 ETH collateral = $2000
        // Max debt = $1000
        await stable.connect(user).deposit({ value: ethers.parseEther("1") });
        await stable.connect(user).mint(ethers.parseEther("1000"));

        expect(await stable.balanceOf(user.address)).to.equal(
            ethers.parseEther("1000")
        );
    });

    it("mint: reverts if exceeds collateral ratio (failure)", async () => {
        const { stable, user } = await deployFixture();

        await stable.connect(user).deposit({ value: ethers.parseEther("1") });

        await expect(
            stable.connect(user).mint(ethers.parseEther("1500"))
        ).to.be.revertedWith("Exceeds mint limit");
    });

    // BURN
    it("burn: burns SBC and reduces debt (success)", async () => {
        const { stable, user } = await deployFixture();

        await stable.connect(user).deposit({ value: ethers.parseEther("1") });
        await stable.connect(user).mint(ethers.parseEther("500"));
        await stable.connect(user).burn(ethers.parseEther("200"));

        expect(await stable.debt(user.address)).to.equal(
            ethers.parseEther("300")
        );
    });

    it("burn: reverts if burning more than debt (failure)", async () => {
        const { stable, user } = await deployFixture();

        await expect(
            stable.connect(user).burn(ethers.parseEther("1"))
        ).to.be.revertedWith("Too much burn");
    });

    // LIQUIDATION
    it("liquidate: liquidates unhealthy position (success)", async () => {
        const { stable, oracle, user, liquidator } = await deployFixture();

        // User deposits 1 ETH @ $2000 and mints max debt
        await stable.connect(user).deposit({ value: ethers.parseEther("1") });
        await stable.connect(user).mint(ethers.parseEther("1000"));

        // ETH price drops to $1500 → position becomes unhealthy
        // Collateral value: 1 ETH * $1500 = $1500
        // Debt: $1000
        // Ratio: 1500/1000 = 1.5x < 2x (unhealthy)
        await oracle.setEthPrice(ethers.parseEther("1500"));

        // Liquidator deposits enough ETH to mint the required SBC
        // To mint 1000 SBC, needs collateral worth $2000
        // At $1500/ETH, needs: 2000/1500 = 1.33... ETH
        await stable.connect(liquidator).deposit({
            value: ethers.parseEther("2"),
        });

        // Liquidator mints 1000 SBC to cover the user's debt
        await stable.connect(liquidator).mint(ethers.parseEther("1000"));

        // Liquidate user's position
        await stable.connect(liquidator).liquidate(user.address);

        // Verify position is wiped
        expect(await stable.debt(user.address)).to.equal(0);
        expect(await stable.ethDeposits(user.address)).to.equal(0);
    });

    it("liquidate: reverts if position healthy (failure)", async () => {
        const { stable, user, liquidator } = await deployFixture();

        await stable.connect(user).deposit({ value: ethers.parseEther("1") });
        await stable.connect(user).mint(ethers.parseEther("500"));

        await expect(
            stable.connect(liquidator).liquidate(user.address)
        ).to.be.revertedWith("Position is healthy");
    });
});

