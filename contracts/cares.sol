// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

/// @notice This contract allows users to create campaigns on-chain
/// @custom:contact info@soundmoney.com

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Hopes__NoGoalSet();
error Hopes__InsufficientFunds();
error Hopes__NotCampaignCreator();
error Hopes__GoalReachedNotUpdatable();
error Hopes__Unauthorized();

/**
 * @title Hopes
 * @custom:security-contact info@soundmoney.com
 */
contract Hopes is ReentrancyGuard {
    /// @notice Hopes Token Contract Address
    IERC20 public BEZY_TOKEN_CONTRACT;

    address public OWNER;

    /// @notice Emitted when a new campaign is created
    event CampaignCreated(Campaign campaign);

    /// @notice Emitted when an existing campaign is updated
    /// @param campaign Details of the updated campaign
    event CampaignUpdated(Campaign campaign);

    /// @notice Emitted when a campaign receives funding
    /// @param funder Address of the contributor who funded the campaign
    /// @param campaign Details of the funded campaign
    /// @param amount Amount of tokens contributed
    event CampaignFunded(
        address indexed funder,
        Campaign campaign,
        uint256 amount
    );

    /// @notice Structure representing a campaign
    struct Campaign {
        uint256 id;
        bytes32 metadata;
        address creator;
        uint256 goal;
        uint256 dateCreated;
        address beneficiary;
        uint256 totalAccrued;
    }

    /// @notice Array storing all the campaigns created in the contract
    Campaign[] public s_Campaigns;

    /// @notice Mapping from a creator's address to their campaign IDs
    mapping(address => uint256[]) private creator_campaignIDs;

    constructor(address initialOwner, address tokenContract) {
        OWNER = initialOwner;
        BEZY_TOKEN_CONTRACT = IERC20(tokenContract);
    }

    /**
     * @dev Adds a new campaign to the platform
     * @param _uri URI of the title, description, and media links
     * @param _goal The funding goal of the campaign in tokens
     * @param _beneficiary The address that will receive the funds collected by the campaign
     */
    function addCampaign(
        bytes32 _uri,
        uint256 _goal,
        address _beneficiary
    ) public _nonZeroGoal(_goal) {
        uint256 id = s_Campaigns.length;
        Campaign memory newCampaign = Campaign(
            id,
            _uri,
            msg.sender,
            _goal,
            block.timestamp,
            _beneficiary,
            0
        );
        s_Campaigns.push(newCampaign);
        creator_campaignIDs[msg.sender].push(id);
        emit CampaignCreated(newCampaign);
    }

    /**
     * @dev Funds a specific campaign using BEZY tokens
     * @param _campaignID The ID of the campaign to be funded
     * @param _amount The amount of tokens to fund
     */
    function fundCampaign(uint256 _campaignID, uint256 _amount)
        public
        nonReentrant
        _nonZeroFunds(_amount)
    {
        Campaign storage campaign = s_Campaigns[_campaignID];

        // Transfer BEZY tokens from the funder to the beneficiary
        bool transferSuccess = BEZY_TOKEN_CONTRACT.transferFrom(
            msg.sender,
            campaign.beneficiary,
            _amount
        );
        require(transferSuccess, "Token transfer failed");

        campaign.totalAccrued += _amount;

        emit CampaignFunded(msg.sender, campaign, _amount);
    }

    /**
     * @dev Update Hopes Token Address
     * @param newTokenAddress New contract address
     */
    function updateTokenContract(address newTokenAddress) public _isOwner {
        BEZY_TOKEN_CONTRACT = IERC20(newTokenAddress);
    }

    modifier _isCampaignCreator(uint256 _campaignID) {
        if (s_Campaigns[_campaignID].creator != msg.sender) {
            revert Hopes__NotCampaignCreator();
        }
        _;
    }

    modifier _nonZeroFunds(uint256 _amount) {
        if (_amount == 0) {
            revert Hopes__InsufficientFunds();
        }
        _;
    }

    modifier _nonZeroGoal(uint256 _goal) {
        if (_goal == 0) {
            revert Hopes__NoGoalSet();
        }
        _;
    }

    modifier _isOwner() {
        if (msg.sender != OWNER) {
            revert Hopes__Unauthorized();
        }
        _;
    }
}
