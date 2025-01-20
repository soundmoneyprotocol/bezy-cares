import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre from "hardhat";
  import { ethers } from "hardhat";

  describe("Cares.Sol", function () {

    async function deployCares() {
    
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await hre.ethers.getSigners();

        // Test Token Deployment 
        const token = await hre.ethers.getContractFactory("TestToken")
        const tokenContract = await token.deploy();

        // Hope Contract Deployment
        const cares = await hre.ethers.getContractFactory("Hopes");
        const caresContract = await cares.deploy(owner,tokenContract.getAddress());
    
        return { caresContract, tokenContract, owner, otherAccount };
      }


      describe("Deployment", function () {
        it("Should deploy correctly", async function () {
            const { caresContract,owner, tokenContract } = await loadFixture(deployCares);
        
            const totalSupply = await tokenContract.totalSupply();
            const tokenAddress = await tokenContract.getAddress();
        
            expect(await tokenContract.balanceOf(owner)).to.equal(totalSupply);
            expect(await caresContract.OWNER()).to.equal(owner);
            expect(await caresContract.BEZY_TOKEN_CONTRACT()).to.equal(tokenAddress);
          });
    
        it("Should add new Campaign", async function () {
          const { owner,caresContract, otherAccount } = await loadFixture(deployCares);

          const uri = ethers.encodeBytes32String("campaignURI");
          const goal = ethers.parseEther("10");

          // Revert 
          await expect(caresContract.addCampaign(uri,0,otherAccount)).to.be.revertedWithCustomError(caresContract,"Hopes__NoGoalSet")

            // Event Emission
          await expect(caresContract.addCampaign(uri, goal, otherAccount))
          .to.emit(caresContract, "CampaignCreated"); 

          // Assertions

          const campaign = await caresContract.s_Campaigns(0);

        expect(campaign.id).to.equal(0);
      expect(campaign.metadata).to.equal(uri);
      expect(campaign.creator).to.equal(owner);
      expect(campaign.goal).to.equal(goal);
      expect(campaign.beneficiary).to.equal(otherAccount);
      expect(campaign.totalAccrued).to.equal(0);

      


        });
    
        it("Should fund a Campaign", async function () {
          const { caresContract, owner, tokenContract, otherAccount } = await loadFixture(
            deployCares
          );

          const uri = ethers.encodeBytes32String("campaignURI");
          const goal = ethers.parseEther("10");
          const amount = ethers.parseEther("1"); 

          await expect(caresContract.addCampaign(uri, goal, otherAccount))
          .to.emit(caresContract, "CampaignCreated");

           // Revert 
           await expect(caresContract.fundCampaign(0,0)).to.be.revertedWithCustomError(caresContract,"Hopes__InsufficientFunds")

           const caresAddress = await caresContract.getAddress();

           await tokenContract.connect(owner).approve(caresAddress, amount);

           // Event Emission
           await expect(
            caresContract.connect(owner).fundCampaign(0, amount)
          ).to.emit(caresContract, "CampaignFunded");

          // Assertation

          const campaign = await caresContract.s_Campaigns(0);
          expect(campaign.totalAccrued).to.equal(amount);  
        
        });
    
        it("Should test token address change", async function () {
            const { caresContract, owner, tokenContract, otherAccount } = await loadFixture(
                deployCares
              );

               // Deploying a new token contract to replace the Bezy
      const NewToken = await ethers.getContractFactory("TestToken");
      const newToken = await NewToken.deploy();

      const newTokenAddress = await newToken.getAddress();
      
    // Revert when not owner
    await expect (caresContract.connect(otherAccount).updateTokenContract(newTokenAddress)).to.be.revertedWithCustomError(caresContract, "Hopes__Unauthorized");

      // Owner updates the token contract
      await caresContract.connect(owner).updateTokenContract(newTokenAddress);

      // Assertion
      
       expect( await caresContract.BEZY_TOKEN_CONTRACT()).to.equal(newTokenAddress);
          
        });
      });
    

  });