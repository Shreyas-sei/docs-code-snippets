const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyToken", function () {
  let token;
  let owner;
  let addr1;
  let addr2;

  const NAME = "MyToken";
  const SYMBOL = "MTK";
  const DECIMALS = 18;
  const INITIAL_SUPPLY = 1_000_000;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const MyToken = await ethers.getContractFactory("MyToken");
    token = await MyToken.deploy(
      NAME,
      SYMBOL,
      DECIMALS,
      INITIAL_SUPPLY,
      owner.address
    );
    await token.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      expect(await token.name()).to.equal(NAME);
      expect(await token.symbol()).to.equal(SYMBOL);
    });

    it("Should set the correct decimals", async function () {
      expect(await token.decimals()).to.equal(DECIMALS);
    });

    it("Should mint initial supply to owner", async function () {
      const expectedSupply = ethers.parseUnits(
        INITIAL_SUPPLY.toString(),
        DECIMALS
      );
      expect(await token.totalSupply()).to.equal(expectedSupply);
      expect(await token.balanceOf(owner.address)).to.equal(expectedSupply);
    });

    it("Should set the correct owner", async function () {
      expect(await token.owner()).to.equal(owner.address);
    });
  });

  describe("Transfers", function () {
    it("Should transfer tokens between accounts", async function () {
      const amount = ethers.parseUnits("100", DECIMALS);
      await token.transfer(addr1.address, amount);
      expect(await token.balanceOf(addr1.address)).to.equal(amount);
    });

    it("Should fail if sender does not have enough tokens", async function () {
      const amount = ethers.parseUnits("100", DECIMALS);
      await expect(
        token.connect(addr1).transfer(addr2.address, amount)
      ).to.be.revertedWithCustomError(token, "ERC20InsufficientBalance");
    });

    it("Should update balances after transfers", async function () {
      const amount = ethers.parseUnits("50", DECIMALS);
      await token.transfer(addr1.address, amount);
      await token.connect(addr1).transfer(addr2.address, amount);
      expect(await token.balanceOf(addr1.address)).to.equal(0);
      expect(await token.balanceOf(addr2.address)).to.equal(amount);
    });
  });

  describe("Minting", function () {
    it("Should allow owner to mint tokens", async function () {
      const mintAmount = ethers.parseUnits("500", DECIMALS);
      const supplyBefore = await token.totalSupply();
      await token.mint(addr1.address, mintAmount);
      expect(await token.balanceOf(addr1.address)).to.equal(mintAmount);
      expect(await token.totalSupply()).to.equal(supplyBefore + mintAmount);
    });

    it("Should not allow non-owner to mint tokens", async function () {
      const mintAmount = ethers.parseUnits("500", DECIMALS);
      await expect(
        token.connect(addr1).mint(addr1.address, mintAmount)
      ).to.be.revertedWithCustomError(token, "OwnableUnauthorizedAccount");
    });
  });

  describe("Burning", function () {
    it("Should allow token holders to burn their own tokens", async function () {
      const burnAmount = ethers.parseUnits("100", DECIMALS);
      const supplyBefore = await token.totalSupply();
      await token.burn(burnAmount);
      expect(await token.totalSupply()).to.equal(supplyBefore - burnAmount);
    });

    it("Should fail when burning more than balance", async function () {
      const burnAmount = ethers.parseUnits("100", DECIMALS);
      await expect(
        token.connect(addr1).burn(burnAmount)
      ).to.be.revertedWithCustomError(token, "ERC20InsufficientBalance");
    });
  });

  describe("Pausable", function () {
    it("Should allow owner to pause and unpause transfers", async function () {
      await token.pause();
      const amount = ethers.parseUnits("100", DECIMALS);
      await expect(
        token.transfer(addr1.address, amount)
      ).to.be.revertedWithCustomError(token, "EnforcedPause");

      await token.unpause();
      await expect(token.transfer(addr1.address, amount)).to.not.be.reverted;
    });

    it("Should not allow non-owner to pause", async function () {
      await expect(
        token.connect(addr1).pause()
      ).to.be.revertedWithCustomError(token, "OwnableUnauthorizedAccount");
    });
  });

  describe("Allowances", function () {
    it("Should approve and transferFrom correctly", async function () {
      const amount = ethers.parseUnits("200", DECIMALS);
      await token.approve(addr1.address, amount);
      expect(await token.allowance(owner.address, addr1.address)).to.equal(
        amount
      );

      await token
        .connect(addr1)
        .transferFrom(owner.address, addr2.address, amount);
      expect(await token.balanceOf(addr2.address)).to.equal(amount);
    });
  });
});
